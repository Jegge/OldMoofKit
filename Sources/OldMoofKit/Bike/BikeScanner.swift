//
//  BikeScanner.swift
//  
//
//  Created by Sebastian Boettcher on 31.08.23.
//

import Foundation

public protocol BikeScannerDelegate: AnyObject {
    func bikeScanner(_ scanner: BikeScanner, failedWithError error: Error)
    func bikeScanner(_ scanner: BikeScanner, didFindBike bike: Bike)
}

public class BikeScanner: NSObject, BluetoothScannerDelegate {

    private var scanner: BluetoothScanner!
    private var bike: Bike

    public weak var delegate: BikeScannerDelegate?

    public init (delegate: BikeScannerDelegate?, bike: Bike, timeout seconds: TimeInterval = 30) throws {
        guard let profile = bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        self.bike = bike
        super.init()
        self.scanner = BluetoothScanner(delegate: self, services: [profile.identifier], name: bike.deviceName)
    }

    internal func bluetoothScanner(_ scanner: BluetoothScanner, failedWithError error: Error) {
        self.delegate?.bikeScanner(self, failedWithError: error)
    }

    internal func bluetoothScanner(_ scanner: BluetoothScanner, didFindIdentifier identifier: UUID) {
        self.delegate?.bikeScanner(self, didFindBike: Bike(bike: self.bike, identifier: identifier))
    }
}
