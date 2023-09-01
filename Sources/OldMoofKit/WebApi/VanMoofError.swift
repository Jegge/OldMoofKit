//
//  VanMoofWebApiError.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import Foundation

enum VanMoofError: Error {
    case malformedReply
    case expectedToken
    case expectedRefreshToken
    case invalidStatusCode(_ code: Int)
    case notAuthenticated
    case unauthorized
    case expectedData
    case expectedBikeDetails
    case expectedName
    case expectedFrameNumber
    case expectedBleProfile
    case expectedModelName
    case expectedMacAddress
    case expectedKey
    case expectedEncryptionKey
    case malformedEncryptionKey
    case malformedJson
    case invalidData
}

extension VanMoofError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("The provided username or password is not valid.", comment: "Invalid Username or Password")
        case .malformedJson:
            return NSLocalizedString("The file did not contain expected JSON data.", comment: "malformed json")
        default:
            return "Bike Api Error (\(self))"
        }
    }
}
