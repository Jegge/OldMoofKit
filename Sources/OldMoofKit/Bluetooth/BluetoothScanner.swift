//
//  BluetoothScanner.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import CoreBluetooth

protocol BluetoothScannerDelegate: AnyObject {
    func bluetoothScanner(_ scanner: BluetoothScanner, failedWithError error: Error)
    func bluetoothScanner(_ scanner: BluetoothScanner, didFindIdentifier identifier: UUID)
}

class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    private let queue = DispatchQueue(label: "com.realvirtuality.bluetooth.scanner", qos: .background)
    private var central: CBCentralManager!
    private var timer: Timer?
    private var services: [CBUUID]?
    private var name: String?

    weak var delegate: BluetoothScannerDelegate?

    init (delegate: BluetoothScannerDelegate?, services: [CBUUID]?, name: String?, timeout seconds: TimeInterval = 30) {
        self.delegate = delegate
        self.services = services
        self.name = name
        super.init()
        self.central = CBCentralManager(delegate: self, queue: self.queue)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.central.scanForPeripherals(withServices: self.services)
            DispatchQueue.main.sync {
                self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
                    self.central?.stopScan()
                    self.timer?.invalidate()
                    self.timer = nil
                    self.delegate?.bluetoothScanner(self, failedWithError: BluetoothError.timeout)
                }
            }
        case .poweredOff:
            self.central?.stopScan()
            self.timer?.invalidate()
            self.timer = nil

        case .unauthorized:
            DispatchQueue.main.async {
                self.delegate?.bluetoothScanner(self, failedWithError: BluetoothError.unauthorized)
            }

        case .unsupported:
            DispatchQueue.main.async {
                self.delegate?.bluetoothScanner(self, failedWithError: BluetoothError.unsupported)
            }

        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name == self.name || self.name == nil {
            self.central?.stopScan()
            self.timer?.invalidate()
            self.timer = nil

            DispatchQueue.main.sync {
                self.delegate?.bluetoothScanner(self, didFindIdentifier: peripheral.identifier)
            }
        }
    }
}
