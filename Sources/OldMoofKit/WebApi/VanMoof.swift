//
//  BikeApi.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 09.08.23.
//

import Foundation

public struct VanMoof {
    fileprivate struct Key {
        static let data = "data"
        static let bikeDetails = "bikeDetails"
        static let name = "name"
        static let frameNumber = "frameNumber"
        static let bleProfile = "bleProfile"
        static let modelName = "modelName"
        static let macAddress = "macAddress"
        static let key = "key"
        static let encryptionKey = "encryptionKey"
        static let token = "token"
        static let refreshToken = "refreshToken"
        static let smartmoduleCurrentVersion = "smartmoduleCurrentVersion"
    }

    let baseURL: URL
    let apiKey: String

    private var token: String = ""
    private var refreshToken: String = ""

    public init () {
        self.init(baseURL: URL(string: "https://my.vanmoof.com/api/v8/")!, apiKey: "fcb38d47-f14b-30cf-843b-26283f6a5819")
    }

    public init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }

    public mutating func authenticate (username: String, password: String) async throws {
        self.token = ""
        self.refreshToken = ""

        let authorization = Data("\(username):\(password)".utf8).base64EncodedString()

        var request = URLRequest(url: self.baseURL.appendingPathComponent("authenticate"))
        request.setValue("Basic \(authorization)", forHTTPHeaderField: "Authorization")
        request.setValue(self.apiKey, forHTTPHeaderField: "Api-Key")
        request.httpMethod  = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VanMoofError.malformedReply
        }

        if httpResponse.statusCode == 401 {
            throw VanMoofError.unauthorized
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
            throw VanMoofError.invalidStatusCode(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject] else {
            throw VanMoofError.malformedReply
        }
        guard let token = json[Key.token] as? String else {
            throw VanMoofError.expectedToken
        }
        guard let refreshToken = json[Key.refreshToken] as? String else {
            throw VanMoofError.expectedRefreshToken
        }

        self.token = token
        self.refreshToken = refreshToken
    }

    // swiftlint:disable:next cyclomatic_complexity
    public func bikeProperties () async throws -> [BikeProperties] {
        if self.token == "" || self.refreshToken == "" {
            throw VanMoofError.notAuthenticated
        }

        var request = URLRequest(url: self.baseURL.appendingPathComponent("getCustomerData?includeBikeDetails"))
        request.setValue( "Bearer \(self.token)", forHTTPHeaderField: "Authorization")
        request.setValue(self.apiKey, forHTTPHeaderField: "Api-Key")
        request.httpMethod  = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VanMoofError.malformedReply
        }

        if httpResponse.statusCode == 401 {
            throw VanMoofError.unauthorized
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
            throw VanMoofError.invalidStatusCode(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VanMoofError.malformedJson
        }

        guard let jsonData = json[Key.data] as? [String: Any] else {
            throw VanMoofError.expectedData
        }

        guard let bikeDetails = jsonData[Key.bikeDetails] as? [[String: Any]] else {
            throw VanMoofError.expectedBikeDetails
        }

        return try bikeDetails.compactMap { detail in
            guard let name = detail[VanMoof.Key.name] as? String else {
                throw VanMoofError.expectedName
            }
            guard let frameNumber = detail[VanMoof.Key.frameNumber] as? String else {
                throw VanMoofError.expectedFrameNumber
            }
            guard let bleProfile = detail[VanMoof.Key.bleProfile] as? String else {
                throw VanMoofError.expectedBleProfile
            }
            guard let modelName = detail[VanMoof.Key.modelName] as? String else {
                throw VanMoofError.expectedModelName
            }
            guard let macAddress = detail[VanMoof.Key.macAddress] as? String else {
                throw VanMoofError.expectedMacAddress
            }
            guard let key = detail[VanMoof.Key.key] as? [String: Any] else {
                throw VanMoofError.expectedKey
            }
            guard let encryptionKey = key[VanMoof.Key.encryptionKey] as? String else {
                throw VanMoofError.expectedEncryptionKey
            }
            guard let encryptionKey = Data(hexString: encryptionKey) else {
                throw VanMoofError.malformedEncryptionKey
            }

            let version = detail[VanMoof.Key.smartmoduleCurrentVersion] as? String

            return BikeProperties(name: name,
                                  frameNumber: frameNumber,
                                  bleProfile: bleProfile,
                                  modelName: modelName,
                                  macAddress: macAddress,
                                  key: encryptionKey,
                                  smartModuleVersion: version)
        }
    }
}

public extension Array where Element == BikeProperties {
    init(parse data: Data?) throws {
        guard let data = data else {
            throw VanMoofError.invalidData
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw VanMoofError.malformedJson
        }
        let items = try json.compactMap { detail in
            guard let name = detail[VanMoof.Key.name] as? String else {
                throw VanMoofError.expectedName
            }
            guard let frameNumber = detail[VanMoof.Key.frameNumber] as? String else {
                throw VanMoofError.expectedFrameNumber
            }
            guard let bleProfile = detail[VanMoof.Key.bleProfile] as? String else {
                throw VanMoofError.expectedBleProfile
            }
            guard let modelName = detail[VanMoof.Key.modelName] as? String else {
                throw VanMoofError.expectedModelName
            }
            guard let macAddress = detail[VanMoof.Key.macAddress] as? String else {
                throw VanMoofError.expectedMacAddress
            }
            guard let key = detail[VanMoof.Key.key] as? [String: Any] else {
                throw VanMoofError.expectedKey
            }
            guard let encryptionKey = key[VanMoof.Key.encryptionKey] as? String else {
                throw VanMoofError.expectedEncryptionKey
            }
            guard let encryptionKey = Data(hexString: encryptionKey) else {
                throw VanMoofError.malformedEncryptionKey
            }

            let version = detail[VanMoof.Key.smartmoduleCurrentVersion] as? String

            return BikeProperties(name: name,
                                  frameNumber: frameNumber,
                                  bleProfile: bleProfile,
                                  modelName: modelName,
                                  macAddress: macAddress,
                                  key: encryptionKey,
                                  smartModuleVersion: version)
        }
        self.init(items)
    }
}
