//
//  BluetoothConnection.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 10.08.23.
//

import CoreBluetooth

protocol BluetoothConnectionDelegate: AnyObject {
    func bluetoothConnection(_ connection: BluetoothConnection, failed error: Error)
    func bluetoothDidConnect(_ connection: BluetoothConnection)
    func bluetoothDidDisconnect(_ connection: BluetoothConnection)
}

class BluetoothConnection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let queue = DispatchQueue(label: "com.realvirtuality.bluetooth.connection", qos: .background)
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var characteristics: [CBUUID: CBCharacteristic] = [:]

    private var notifyCallbacks: [CBUUID: ((Data?) -> Void)] = [:]

    private var semaphore = DispatchSemaphore(value: 1)
    private var readContinuation: CheckedContinuation<Data?, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?
    private var rssiContinuation: CheckedContinuation<Int, Error>?

    weak var delegate: BluetoothConnectionDelegate?

    let identifier: UUID
    let reconnectInterval: TimeInterval

    var isConnected: Bool { return self.peripheral?.state == .connected }

    public init (delegate: BluetoothConnectionDelegate?, identifier: UUID, reconnectInterval: TimeInterval) {
        self.delegate = delegate
        self.identifier = identifier
        self.reconnectInterval = reconnectInterval
        super.init()
        self.central = CBCentralManager(delegate: self, queue: self.queue)
    }

    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if let peripheral = self.central.retrievePeripherals(withIdentifiers: [self.identifier]).first {
                self.connectPeripheral(peripheral)
            } else {
                self.reportError(BluetoothError.peripheralNotFound)
            }
        case .poweredOff:
            self.disconnectPeripheral()
        default:
            break
        }
    }

    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.reportError(error)
        }
        self.disconnectPeripheral()
        self.connectPeripheral(peripheral, afterDelay: 1)
    }

    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.reportError(error)
        }
        self.disconnectPeripheral()
        self.connectPeripheral(peripheral, afterDelay: 1)
    }

    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.peripheral?.discoverServices(nil)
    }

    private func connectPeripheral(_ peripheral: CBPeripheral, afterDelay delay: TimeInterval = 0) {
        self.peripheral = peripheral
        peripheral.delegate = self
        self.characteristics = [:]
        self.readContinuation?.resume(throwing: BluetoothError.disconnected)
        self.readContinuation = nil
        self.writeContinuation?.resume(throwing: BluetoothError.disconnected)
        self.writeContinuation = nil
        self.notifyCallbacks = [:]
        self.semaphore = DispatchSemaphore(value: 1)

        if delay != .infinity {
            self.queue.asyncAfter(deadline: .now() + delay) {
                self.central.connect(self.peripheral)
            }
        }
    }

    func disconnectPeripheral() {
        if let peripheral = self.peripheral, self.central.state == .poweredOn {
            self.central.cancelPeripheralConnection(peripheral)
        }

        self.peripheral = nil
        self.characteristics = [:]
        self.readContinuation?.resume(throwing: BluetoothError.disconnected)
        self.readContinuation = nil
        self.writeContinuation?.resume(throwing: BluetoothError.disconnected)
        self.writeContinuation = nil
        self.notifyCallbacks = [:]
        self.semaphore.signal()

        DispatchQueue.main.async {
            self.delegate?.bluetoothDidDisconnect(self)
        }
    }

    private func reportError (_ error: Error) {
        DispatchQueue.main.async {
            self.delegate?.bluetoothConnection(self, failed: error)
        }
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            self.reportError(error)
            return
        }
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            self.reportError(error)
            return
        }

        for characteristic in service.characteristics ?? [] {
            self.characteristics[characteristic.uuid] = characteristic
        }

        let discoveredServicesCount = Set(self.characteristics.values.compactMap { $0.service?.uuid }).count
        if discoveredServicesCount == (peripheral.services?.count ?? 0) {
            DispatchQueue.main.async {
                self.delegate?.bluetoothDidConnect(self)
            }
        }
    }

    func readValue (for uuid: CBUUID) async throws -> Data? {
        guard let peripheral = self.peripheral, peripheral.state == .connected else {
            throw BluetoothError.disconnected
        }
        guard let characteristic = self.characteristics[uuid] else {
            throw BluetoothError.characteristicNotFound
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.semaphore.wait()
            self.readContinuation = continuation
            peripheral.readValue(for: characteristic)
        }
    }

    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.isNotifying {
            if let error = error {
                self.reportError(error)
            } else if let callback = self.notifyCallbacks[characteristic.uuid] {
                DispatchQueue.main.async {
                    callback(characteristic.value)
                }
            }
        } else {
            let continuation = self.readContinuation
            self.readContinuation = nil
            self.semaphore.signal()

            if let error = error {
                continuation?.resume(throwing: error)
            } else {
                continuation?.resume(returning: characteristic.value)
            }
        }
    }

    func writeValue(_ data: Data, for uuid: CBUUID) async throws {
        guard let peripheral = self.peripheral, peripheral.state == .connected else {
            throw BluetoothError.disconnected
        }
        guard let characteristic = self.characteristics[uuid] else {
            throw BluetoothError.characteristicNotFound
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.semaphore.wait()
            self.writeContinuation = continuation
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    internal func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let continuation = self.writeContinuation
        self.writeContinuation = nil
        self.semaphore.signal()
        if let error = error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }
    }

    func setNotifyValue(enabled: Bool, for uuid: CBUUID, callback: @escaping ((Data?) -> Void)) {
        guard let peripheral = self.peripheral, let characteristic = self.characteristics[uuid] else {
            return
        }
        if enabled {
            self.notifyCallbacks[uuid] = callback
        } else {
            self.notifyCallbacks.removeValue(forKey: uuid)
        }
        peripheral.setNotifyValue(enabled, for: characteristic)
    }

    func readRssi () async throws -> Int {
        guard let peripheral = self.peripheral, peripheral.state == .connected else {
            throw BluetoothError.disconnected
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.rssiContinuation = continuation
            peripheral.readRSSI()
        }
    }

    internal func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let continuation = self.rssiContinuation
        self.rssiContinuation = nil

        if let error = error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume(returning: Int(truncating: RSSI))
        }
    }
}
