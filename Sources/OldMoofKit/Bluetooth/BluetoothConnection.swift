//
//  BluetoothConnection.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 10.08.23.
//

import CoreBluetooth
import Combine
import OSLog

class BluetoothConnection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let queue = DispatchQueue(label: "com.realvirtuality.bluetooth.connection", qos: .background)
    private var central: CBCentralManager?
    private var peripheral: CBPeripheral!
    private var characteristics: [CBUUID: CBCharacteristic] = [:]
    private var semaphore = DispatchSemaphore(value: 1)
    private var readContinuation: CheckedContinuation<Data?, Error>?
    private var writeContinuation: CheckedContinuation<Void, Error>?
    private var rssiContinuation: CheckedContinuation<Int, Error>?
    private var connectContinuation: CheckedContinuation<Void, Error>?

    let notifications = PassthroughSubject<BluetoothNotification, Never>()
    let errors = PassthroughSubject<Error, Never>()
    let state = PassthroughSubject<BluetoothState, Never>()

    let identifier: UUID
    let reconnectInterval: TimeInterval

    var isConnected: Bool {
        return self.peripheral?.state == .connected
    }

    init (identifier: UUID, reconnectInterval: TimeInterval) {
        self.identifier = identifier
        self.reconnectInterval = reconnectInterval
    }

    func connect () async throws {
        if self.connectContinuation != nil {
            throw BluetoothError.busy
        }

        if let central = self.central {
            try await withCheckedThrowingContinuation { continuation in
                self.connectContinuation = continuation
                self.centralManagerDidUpdateState(central)
            }
        } else {
            try await withCheckedThrowingContinuation { continuation in
                self.connectContinuation = continuation
                self.central = CBCentralManager(delegate: self, queue: self.queue)
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if let peripheral = self.central?.retrievePeripherals(withIdentifiers: [self.identifier]).first {
                self.connectPeripheral(peripheral, afterDelay: .zero)
            } else {
                self.errors.send(BluetoothError.peripheralNotFound)
                self.connectContinuation?.resume(throwing: BluetoothError.peripheralNotFound)
                self.connectContinuation = nil
            }

        case .poweredOff:
            self.disconnectPeripheral()
            self.errors.send(BluetoothError.poweredOff)
            self.connectContinuation?.resume(throwing: BluetoothError.poweredOff)
            self.connectContinuation = nil

        case .unauthorized:
            self.errors.send(BluetoothError.unauthorized)
            self.connectContinuation?.resume(throwing: BluetoothError.unauthorized)
            self.connectContinuation = nil

        case .unsupported:
            self.errors.send(BluetoothError.unsupported)
            self.connectContinuation?.resume(throwing: BluetoothError.unsupported)
            self.connectContinuation = nil

        default:
            Logger.bluetooth.warning("Central entered unexpected state: \(String(describing: central.state))")
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.errors.send(error)
            self.connectContinuation?.resume(throwing: error)
            self.connectContinuation = nil
        }
        self.disconnectPeripheral()
        self.connectPeripheral(peripheral, afterDelay: self.reconnectInterval)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.errors.send(error)
            self.connectContinuation?.resume(throwing: error)
            self.connectContinuation = nil
        }
        self.disconnectPeripheral()
        self.connectPeripheral(peripheral, afterDelay: self.reconnectInterval)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
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
        self.semaphore.signal()

        self.state.send(.disconnected)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            self.errors.send(error)
            self.connectContinuation?.resume(throwing: error)
            self.connectContinuation = nil
            return
        }

        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            self.errors.send(error)
            self.connectContinuation?.resume(throwing: error)
            self.connectContinuation = nil
            return
        }

        for characteristic in service.characteristics ?? [] {
            self.characteristics[characteristic.uuid] = characteristic
        }

        let discoveredServicesCount = Set(self.characteristics.values.compactMap { $0.service?.uuid }).count
        if discoveredServicesCount == (peripheral.services?.count ?? 0) {
            self.state.send(.connected)
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

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.isNotifying {
            if let error = error {
                self.errors.send(error)
            } else {
                self.notifications.send(BluetoothNotification(uuid: characteristic.uuid, data: characteristic.value))
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

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let continuation = self.writeContinuation
        self.writeContinuation = nil
        self.semaphore.signal()
        if let error = error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume()
        }
    }

    func setNotifyValue(enabled: Bool, for uuid: CBUUID) {
        guard let peripheral = self.peripheral, let characteristic = self.characteristics[uuid] else {
            return
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

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let continuation = self.rssiContinuation
        self.rssiContinuation = nil

        if let error = error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume(returning: Int(truncating: RSSI))
        }
    }
}
