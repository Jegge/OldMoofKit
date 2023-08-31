//
//  BluetoothError.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import Foundation

enum BluetoothError: Error {
    case peripheralNotFound
    case timeout
    case unauthorized
    case unsupported
    case disconnected
    case characteristicNotFound
}

extension BluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .peripheralNotFound:
            return NSLocalizedString("No bike with the given device identifier could be found.", comment: "Error description: peripheralNotFound")
        case .timeout:
            return NSLocalizedString("No bike could be found via bluetooth in a reasonable time.", comment: "Error description: timedOut")
        case .unauthorized:
            return NSLocalizedString("Bluetooth needs to be enabled for this app in the settings.", comment: "Error description: bluetoothNotAuthorized")
        case .unsupported:
            return NSLocalizedString("Your device does not support bluetooth.", comment: "Error description: bluetoothNotSupported")
        case .disconnected:
            return NSLocalizedString("Your device is not connected or did disconnect.", comment: "Error description: disconnected")
        case .characteristicNotFound:
            return NSLocalizedString("The requested characteristic could not be found.", comment: "Error description: characteristicNotFound")
        }
    }
}
