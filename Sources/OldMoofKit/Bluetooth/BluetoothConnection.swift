//
//  BluetoothConnection.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 10.08.23.
//

import CoreBluetooth
import Combine

internal enum BluetoothEvent {
    case connected
    case disconnected
    case error(_ error: Error)
}

internal class BluetoothConnection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let queue = DispatchQueue(label: "com.realvirtuality.bluetooth.connection", qos: .background)
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral!
    private var characteristics: [CBUUID: CBCharacteristic] = [:]
    private var notifyCallbacks: [CBUUID: ((Data?) -> Void)] = [:]
    private var semaphore = DispatchSemaphore(value: 1)
    private var readContinuation: CheckedContinuation<Data?, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?
    private var rssiContinuation: CheckedContinuation<Int, Error>?

    private var connectContinuation: CheckedContinuation<Void, Error>?

    let events: PassthroughSubject<BluetoothEvent, Never> = PassthroughSubject<BluetoothEvent, Never>()

    let identifier: UUID
    let reconnectInterval: TimeInterval

    var isConnected: Bool {
        return self.peripheral?.state == .connected
    }

    internal init (identifier: UUID, reconnectInterval: TimeInterval) {
        self.identifier = identifier
        self.reconnectInterval = reconnectInterval
    }

    internal func connect () async throws {
        if self.central == nil {
            try await withCheckedThrowingContinuation { continuation in
                self.connectContinuation = continuation
                self.central = CBCentralManager(delegate: self, queue: self.queue)
            }
        } else if self.central?.state == .poweredOn, let peripheral = self.central?.retrievePeripherals(withIdentifiers: [self.identifier]).first {
            try await withCheckedThrowingContinuation { continuation in
                self.connectContinuation = continuation
                self.connectPeripheral(peripheral, afterDelay: .zero)
            }
        }
    }

    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if let peripheral = self.central?.retrievePeripherals(withIdentifiers: [self.identifier]).first {
                self.connectPeripheral(peripheral, afterDelay: .zero)
            } else {
                self.events.send(.error(BluetoothError.peripheralNotFound))
                self.connectContinuation?.resume(throwing: BluetoothError.peripheralNotFound)
            }

        case .poweredOff:
            self.disconnectPeripheral()
            self.events.send(.error(BluetoothError.poweredOff))
            self.connectContinuation?.resume(throwing: BluetoothError.poweredOff)

        case .unauthorized:
            self.events.send(.error(BluetoothError.unauthorized))
            self.connectContinuation?.resume(throwing: BluetoothError.unauthorized)

        case .unsupported:
            self.events.send(.error(BluetoothError.unsupported))
            self.connectContinuation?.resume(throwing: BluetoothError.unsupported)

        default:
            print("Central entered unexpected state: \(central.state)")
        }
    }

    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.events.send(.error(error))
            self.connectContinuation?.resume(throwing: error)
            self.connectContinuation = nil
        }
        self.disconnectPeripheral()
        self.connectPeripheral(peripheral, afterDelay: self.reconnectInterval)
    }

    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.events.send(.error(error))
            self.connectContinuation?.resume(throwing: error)
            self.connectContinuation = nil
        }
        self.disconnectPeripheral()
        self.connectPeripheral(peripheral, afterDelay: self.reconnectInterval)
    }

    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.peripheral?.discoverServices(nil)
    }

    private func connectPeripheral(_ peripheral: CBPeripheral, afterDelay delay: TimeInterval) {
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
                self.central?.connect(self.peripheral)
            }
        }
    }

    func disconnectPeripheral() {
        if let peripheral = self.peripheral, self.central?.state == .poweredOn {
            self.central?.cancelPeripheralConnection(peripheral)
        }

        self.peripheral = nil
        self.characteristics = [:]
        self.readContinuation?.resume(throwing: BluetoothError.disconnected)
        self.readContinuation = nil
        self.writeContinuation?.resume(throwing: BluetoothError.disconnected)
        self.writeContinuation = nil
        self.notifyCallbacks = [:]
        self.semaphore.signal()

        self.events.send(.disconnected)
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            self.events.send(.error(error))
            self.connectContinuation?.resume(throwing: error)
            self.connectContinuation = nil
            return
        }

        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            self.events.send(.error(error))
            self.connectContinuation?.resume(throwing: error)
            self.connectContinuation = nil
            return
        }

        for characteristic in service.characteristics ?? [] {
            self.characteristics[characteristic.uuid] = characteristic
        }

        let discoveredServicesCount = Set(self.characteristics.values.compactMap { $0.service?.uuid }).count
        if discoveredServicesCount == (peripheral.services?.count ?? 0) {
            self.events.send(.connected)
            self.connectContinuation?.resume()
            self.connectContinuation = nil
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
                self.events.send(.error(error))
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
