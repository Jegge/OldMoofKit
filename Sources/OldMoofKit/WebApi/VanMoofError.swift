//
//  VanMoofWebApiError.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import Foundation

public enum VanMoofError: Error {
    case invalidData
    case expected(element: String)
    case invalidStatusCode(_ code: Int)
    case notAuthenticated
    case unauthorized
    case noSupportedBikesFound
}

extension VanMoofError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("The provided username or password is not valid.", comment: "Invalid Username or Password")
        case .notAuthenticated:
            return NSLocalizedString("The api needs to be authenticated first.", comment: "Invalid api usage")
        case .invalidData:
            return NSLocalizedString("The file did not contain expected JSON data.", comment: "malformed json")
        case .noSupportedBikesFound:
            return NSLocalizedString("There are no supported bikes linked to the given account or in the given JSON file.", comment: "Error description: noSupportedBikesFound")
        case .expected(let element):
            return String(format: NSLocalizedString("Did not find expected element '%@' in JSON data.", comment: "Error description: expected element"), element)
        case .invalidStatusCode(let code):
            return String(format: NSLocalizedString("Did receive HTTP unexpected status code %@.", comment: "Error description: expected element"), code)
        }
    }
}
