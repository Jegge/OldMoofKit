//
//  BluetoothError.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import Foundation

/// Errors thrown from the bluetooth connection
public enum BluetoothError: Error {
    /// The peripheral with the given id could not be found.
    case peripheralNotFound
    /// A timeout occured while scanning for a particular bike.
    case timeout
    /// Bluetooth is not enabled for your app.
    case unauthorized
    /// Bluetooth is not supported by your device.
    case unsupported
    /// Bluetooth is currently switched off.
    case poweredOff
    /// The device is currently disconnected.
    case disconnected
    /// Attempted to read / to write / to receive notifications for a characteristic that does not exist.
    case characteristicNotFound
    /// The device is currently busy.
    case busy
}

extension BluetoothError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .peripheralNotFound:
            return NSLocalizedString("No bike with the given device identifier could be found.", comment: "Error description: peripheralNotFound")
        case .timeout:
            return NSLocalizedString("No bike could be found via bluetooth in a reasonable time. Make sure that it is in range and that no other apps are connected to it.", comment: "Error description: timedOut")
        case .unauthorized:
            return NSLocalizedString("Bluetooth needs to be enabled for this app in the settings.", comment: "Error description: unauthorized")
        case .unsupported:
            return NSLocalizedString("Your device does not support bluetooth.", comment: "Error description: unsupported")
        case .poweredOff:
            return NSLocalizedString("Bluetooth needs to be switched on for this app to work.", comment: "Error description: poweredOff")
        case .disconnected:
            return NSLocalizedString("Your device is not connected or did disconnect.", comment: "Error description: disconnected")
        case .characteristicNotFound:
            return NSLocalizedString("The requested characteristic could not be found.", comment: "Error description: characteristicNotFound")
        case .busy:
            return NSLocalizedString("The device is busy.", comment: "Error description: device busy")
        }
    }
}
