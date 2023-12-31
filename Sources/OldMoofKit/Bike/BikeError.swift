//
//  BikeConnectionError.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import Foundation

/// An error thrown when working with a bike.
public enum BikeError: Error {
    /// This bike is currently not supported.
    case bikeNotSupported
    /// The bike is currently not connected.
    case notConnected
    /// The pin code is invalid.
    ///
    /// The pin must have three digits in the range 1 through 9.
    case pinCodeInvalid
    /// The encryption key is in an invalid format.
    case encryptionKeyInvalidFormat
    /// The mac address is in an invalid format.
    case macAddressInvalidFormat
}

extension BikeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bikeNotSupported:
            return NSLocalizedString("This bike is currently not supported.", comment: "Error description: bikeNotSupported")
        case .notConnected:
            return NSLocalizedString("The bike is currently not connected.", comment: "Error description: notConnected")
        case .pinCodeInvalid:
            return NSLocalizedString("The code must be in the range from 111 to 999.", comment: "Error descritpion: codeOutOfRange")
        case .encryptionKeyInvalidFormat:
            return NSLocalizedString("The encryption key must be 32 bytes long, as hexadecimal string.", comment: "Error descritpion: encryptionKeyInvalidFormat")
        case .macAddressInvalidFormat:
            return NSLocalizedString("The mac address must be specified in MAC-48 format.", comment: "Error descritpion: macAddressInvalidFormat")
        }
    }
}
