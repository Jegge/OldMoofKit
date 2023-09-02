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

    let apiUrl: URL
    let apiKey: String

    private var token: String = ""
    private var refreshToken: String = ""

    public struct Api {
        public static let url: URL = URL(string: "https://my.vanmoof.com/api/v8/")!
        public static let key: String = "fcb38d47-f14b-30cf-843b-26283f6a5819"
    }

    public init(apiUrl: URL, apiKey: String) {
        self.apiUrl = apiUrl
        self.apiKey = apiKey
    }

    public mutating func authenticate (username: String, password: String) async throws {
        self.token = ""
        self.refreshToken = ""

        let authorization = Data("\(username):\(password)".utf8).base64EncodedString()

        var request = URLRequest(url: self.apiUrl.appendingPathComponent("authenticate"))
        request.setValue("Basic \(authorization)", forHTTPHeaderField: "Authorization")
        request.setValue(self.apiKey, forHTTPHeaderField: "Api-Key")
        request.httpMethod  = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VanMoofError.invalidData
        }

        if httpResponse.statusCode == 401 {
            throw VanMoofError.unauthorized
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
            throw VanMoofError.invalidStatusCode(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject] else {
            throw VanMoofError.invalidData
        }
        guard let token = json[Key.token] as? String else {
            throw VanMoofError.expected(element: Key.token)
        }
        guard let refreshToken = json[Key.refreshToken] as? String else {
            throw VanMoofError.expected(element: Key.refreshToken)
        }

        self.token = token
        self.refreshToken = refreshToken
    }

    public func bikeDetails () async throws -> (Data, [BikeDetails]) {
        if self.token == "" || self.refreshToken == "" {
            throw VanMoofError.notAuthenticated
        }

        var request = URLRequest(url: self.apiUrl.appendingPathComponent("getCustomerData?includeBikeDetails"))
        request.setValue( "Bearer \(self.token)", forHTTPHeaderField: "Authorization")
        request.setValue(self.apiKey, forHTTPHeaderField: "Api-Key")
        request.httpMethod  = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VanMoofError.invalidData
        }

        if httpResponse.statusCode == 401 {
            throw VanMoofError.unauthorized
        }

        if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
            throw VanMoofError.invalidStatusCode(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VanMoofError.invalidData
        }

        guard let jsonData = json[Key.data] as? [String: Any] else {
            throw VanMoofError.expected(element: Key.data)
        }

        guard let bikeDetails = jsonData[Key.bikeDetails] as? [[String: Any]] else {
            throw VanMoofError.expected(element: Key.bikeDetails)
        }

        let detailData = try JSONSerialization.data(withJSONObject: bikeDetails)
        let details = try VanMoof.bikeDetails(from: bikeDetails)
        return (detailData, details)
    }

    public func bikeDetails () async throws -> [BikeDetails] {
        let (_, properties) = try await self.bikeDetails()
        return properties
    }

    fileprivate static func bikeDetails(from json: [[String: Any]]) throws -> [BikeDetails] {
        return try json.compactMap { detail in
            guard let name = detail[VanMoof.Key.name] as? String else {
                throw VanMoofError.expected(element: VanMoof.Key.name)
            }
            guard let frameNumber = detail[VanMoof.Key.frameNumber] as? String else {
                throw VanMoofError.expected(element: VanMoof.Key.frameNumber)
            }
            guard let bleProfile = detail[VanMoof.Key.bleProfile] as? String else {
                throw VanMoofError.expected(element: VanMoof.Key.bleProfile)
            }
            guard let modelName = detail[VanMoof.Key.modelName] as? String else {
                throw VanMoofError.expected(element: VanMoof.Key.modelName)
            }
            guard let macAddress = detail[VanMoof.Key.macAddress] as? String else {
                throw VanMoofError.expected(element: VanMoof.Key.macAddress)
            }
            guard let key = detail[VanMoof.Key.key] as? [String: Any] else {
                throw VanMoofError.expected(element: VanMoof.Key.key)
            }
            guard let encryptionKey = key[VanMoof.Key.encryptionKey] as? String else {
                throw VanMoofError.expected(element: VanMoof.Key.encryptionKey)
            }

            let smartModuleVersion = detail[VanMoof.Key.smartmoduleCurrentVersion] as? String

            return BikeDetails(name: name,
                               frameNumber: frameNumber,
                               bleProfile: bleProfile,
                               modelName: modelName,
                               macAddress: macAddress,
                               encryptionKey: encryptionKey,
                               smartModuleVersion: smartModuleVersion)
        }
    }
}

public extension Array where Element == BikeDetails {
    init(from data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw VanMoofError.invalidData
        }
        let bikes = try VanMoof.bikeDetails(from: json)
        self.init(bikes)
    }
}

public extension Bike {
    convenience init (username: String, password: String) async throws {
        try await self.init(apiUrl: VanMoof.Api.url, apiKey: VanMoof.Api.key, username: username, password: password)
    }

    convenience init (apiUrl: URL, apiKey: String, username: String, password: String) async throws {
        var api = VanMoof(apiUrl: apiUrl, apiKey: apiKey)
        try await api.authenticate(username: username, password: password)
        guard let details = try await api.bikeDetails().first else {
            throw VanMoofError.noSupportedBikesFound
        }
        try await self.init(scanningForBikeMatchingDetails: details)
    }
}
