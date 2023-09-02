//
//  BluetoothScanner.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import CoreBluetooth
import OSLog

class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    private let queue = DispatchQueue(label: "com.realvirtuality.bluetooth.scanner", qos: .background)
    private var central: CBCentralManager?
    private var timer: Timer?
    private var services: [CBUUID]?
    private var name: String?
    private var continuation: CheckedContinuation<UUID, Error>?
    private var timeout: TimeInterval = .infinity

    func scanForPeripherals(withServices services: [CBUUID]?, name: String?, timeout seconds: TimeInterval = 30) async throws -> UUID {
        if self.continuation != nil {
            throw BluetoothError.busy
        }
        self.name = name
        self.services = services
        self.timeout = seconds

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.central = CBCentralManager(delegate: self, queue: self.queue)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.central?.scanForPeripherals(withServices: self.services)
            DispatchQueue.main.sync {
                self.timer = Timer.scheduledTimer(withTimeInterval: self.timeout, repeats: false) { _ in
                    self.central?.stopScan()
                    self.timer?.invalidate()
                    self.timer = nil
                    self.continuation?.resume(throwing: BluetoothError.timeout)
                    self.continuation = nil
                }
            }
        case .poweredOff:
            self.central?.stopScan()
            self.timer?.invalidate()
            self.timer = nil
            self.continuation?.resume(throwing: BluetoothError.poweredOff)
            self.continuation = nil

        case .unauthorized:
            self.continuation?.resume(throwing: BluetoothError.unauthorized)
            self.continuation = nil

        case .unsupported:
            self.continuation?.resume(throwing: BluetoothError.unsupported)
            self.continuation = nil

        default:
            Logger.bluetooth.warning("Central entered unexpected state: \(String(describing: central.state))")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name == self.name || self.name == nil {
            self.central?.stopScan()
            self.timer?.invalidate()
            self.timer = nil
            self.continuation?.resume(returning: peripheral.identifier)
            self.continuation = nil
        }
    }
}
