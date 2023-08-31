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

    init (delegate: BikeScannerDelegate?, profile: String, name: String, timeout seconds: TimeInterval = 30) throws {
        guard let profile = Profiles.profile(named: name) else {
            throw BikeConnectionError.bikeNotSupported
        }
        super.init()
        self.scanner = BluetoothScanner(delegate: self, services: [profile.identifier], name: name)
    }

    internal func bluetoothScanner(_ scanner: BluetoothScanner, failedWithError error: Error) {
        self.delegate?.bikeScanner(self, failedWithError: error)
    }

    internal func bluetoothScanner(_ scanner: BluetoothScanner, didFindIdentifier identifier: UUID) {
        self.delegate?.bikeScanner(self, didFindIdentifier: identifier)
    }
}
