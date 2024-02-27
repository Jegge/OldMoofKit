//
//  VanMoofWebApiError.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import Foundation

/// Errors thrown by the ``VanMoof`` web api.
public enum VanMoofError: Error {
    /// This deserialized data can not be parsed as valid JSON.
    case invalidData
    /// The given element was expected in the JSON file, but could not be found.
    case expected(element: String)
    /// The HTTP request returned a status code signalling an error.
    case invalidStatusCode(_ code: Int)
    /// The HTTP request returned a status code of 401 (forbidden).
    case notAuthenticated
    /// The api is not authorized.
    case unauthorized
    /// The api query yielded no supported bikes.
    case noSupportedBikesFound
    /// The given url was invalid
    case invalidUrl
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
            return String(format: NSLocalizedString("Did receive HTTP unexpected status code %d.", comment: "Error description: expected element"), code)
        case .invalidUrl:
            return NSLocalizedString("The web api URL was malformed or invalid.", comment: "invalid api url")
        }
    }
}
