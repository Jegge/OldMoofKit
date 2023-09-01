//
//  BikeConnectionError.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import Foundation

enum BikeConnectionError: Error {
    case bikeNotSupported
    case notConnected
    case codeOutOfRange
}

extension BikeConnectionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .bikeNotSupported:
            return NSLocalizedString("This bike is currently not supported.", comment: "Error description: bikeNotSupported")
        case .notConnected:
            return NSLocalizedString("The bike is currently not connected.", comment: "Error description: notConnected")
        case .codeOutOfRange:
            return NSLocalizedString("The code must be in the range from 111 to 999.", comment: "Error descritpion: codeOutOfRange")
        }
    }
}
