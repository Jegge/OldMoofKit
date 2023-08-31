//
//  BikeScanner.swift
//  
//
//  Created by Sebastian Boettcher on 31.08.23.
//

import Foundation

public protocol BikeScannerDelegate: AnyObject {
    func bikeScanner(_ scanner: BikeScanner, failedWithError error: Error)
    func bikeScanner(_ scanner: BikeScanner, didFindIdentifier identifier: UUID)
}

public class BikeScanner: NSObject, BluetoothScannerDelegate {

    private var scanner: BluetoothScanner!

    weak var delegate: BikeScannerDelegate?

    public init (delegate: BikeScannerDelegate?, bike: Bike, timeout seconds: TimeInterval = 30) throws {
        guard let profile = bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        super.init()
        self.scanner = BluetoothScanner(delegate: self, services: [profile.identifier], name: bike.deviceName)
    }

    internal func bluetoothScanner(_ scanner: BluetoothScanner, failedWithError error: Error) {
        self.delegate?.bikeScanner(self, failedWithError: error)
    }

    internal func bluetoothScanner(_ scanner: BluetoothScanner, didFindIdentifier identifier: UUID) {
        self.delegate?.bikeScanner(self, didFindIdentifier: identifier)
    }
}
