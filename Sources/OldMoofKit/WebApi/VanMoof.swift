//
//  BikeApi.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 09.08.23.
//

import Foundation

/// The VanMoof web api. Allows to retreive all the ``BikeDetails`` for a user.
public class VanMoof {

    /// Default values regarding the ``VanMoof`` web api.
    public struct Api {
        /// The default base URL of the ``VanMoof`` web api.
        public static let url: URL = URL(string: "https://my.vanmoof.com/api/v8/")!
        /// The default api key to use when querying the ``VanMoof`` web api.
        public static let key: String = "fcb38d47-f14b-30cf-843b-26283f6a5819"
    }

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

    /// The base URL of the ``VanMoof`` web api.
    let apiUrl: URL
    /// The api key to use when querying the ``VanMoof`` web api.
    let apiKey: String

    private var token: String = ""
    private var refreshToken: String = ""

    /// Constructs a ``VanMoof`` web api with the given URL and key.
    ///
    /// - Parameter apiUrl: The base URL of the ``VanMoof`` web api.
    /// - Parameter apiKey: The api key to use when querying the ``VanMoof`` web api.
    public init(apiUrl: URL, apiKey: String) {
        self.apiUrl = apiUrl
        self.apiKey = apiKey
    }

    /// Authenticates a user with the ``VanMoof`` web api.
    ///
    /// - Parameter username: Your ``VanMoof`` account's username.
    /// - Parameter password: Your ``VanMoof`` account's password.
    ///
    /// - Throws: ``VanMoofError/invalidData`` if the deserialized data is no valid JSON,
    /// - Throws: ``VanMoofError/expected(element:)`` if an expected element could not be found in the JSON.
    /// - Throws: ``VanMoofError/unauthorized`` if a 401 HTTP status code occurs.
    /// - Throws: ``VanMoofError/invalidStatusCode(_:)`` if HTTP status code signalling failure occurs.
    public func authenticate (username: String, password: String) async throws {
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

    /// Retrieves all bike's details from the ``VanMoof`` web api.
    ///
    /// This version of the call also returns the raw data.
    /// 
    /// - Returns: A tuple with the raw data and an array of ``BikeDetails``.
    ///
    /// - Throws: ``VanMoofError/invalidData`` if the deserialized data is no valid JSON.
    /// - Throws: ``VanMoofError/expected(element:)`` if an expected element could not be found in the JSON.
    /// - Throws: ``VanMoofError/unauthorized`` if a 401 HTTP status code occurs.
    /// - Throws: ``VanMoofError/invalidStatusCode(_:)`` if HTTP status code signalling failure occurs.
    /// - Throws: ``VanMoofError/notAuthenticated`` if the connection has not been authenticated beforehand.
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

    /// Retrieves all bike's details from the ``VanMoof`` web api.
    /// 
    /// - Returns: An array of ``BikeDetails``.
    ///
    /// - Throws: ``VanMoofError/invalidData`` if the deserialized data is no valid JSON.
    /// - Throws: ``VanMoofError/expected(element:)`` if an expected element could not be found in the JSON.
    /// - Throws: ``VanMoofError/unauthorized`` if a 401 HTTP status code occurs.
    /// - Throws: ``VanMoofError/invalidStatusCode(_:)`` if HTTP status code signalling failure occurs.
    /// - Throws: ``VanMoofError/notAuthenticated`` if the connection has not been authenticated beforehand.
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
                               bleProfile: BikeProfileName(bleProfile),
                               modelName: modelName,
                               macAddress: macAddress,
                               encryptionKey: encryptionKey,
                               smartModuleVersion: smartModuleVersion)
        }
    }
}

extension Array where Element == BikeDetails {
    /// Deserializes an ``Array`` of ``BikeDetails`` .
    ///
    /// - Parameter data: The data to deserialize.
    ///
    /// - Throws: ``VanMoofError/invalidData`` if the deserialized data is no valid JSON.
    /// - Throws: ``VanMoofError/expected(element:)`` if an expected element could not be found in the JSON.
    public init(from data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw VanMoofError.invalidData
        }
        let bikes = try VanMoof.bikeDetails(from: json)
        self.init(bikes)
    }
}

extension Bike {
    /// Downloads the first available bike details from the ``VanMoof`` website, then performs a
    /// bluetooth scan for a device matching said details and returns a connectable bike.
    ///
    /// - Parameter username: Your ``VanMoof`` account's username.
    /// - Parameter password: Your ``VanMoof`` account's password.
    /// - Parameter apiUrl: The base URL of the ``VanMoof`` web api. Defaults to the content of ``VanMoof/Api/url``.
    /// - Parameter apiKey: The api key to use when querying the ``VanMoof`` web api. Defaults to the content of ``VanMoof/Api/key``.
    ///
    /// - Returns: A connectable bike.
    ///
    /// - Throws: ``VanMoofError/noSupportedBikesFound`` if no bike details could be downloaded.
    /// - Throws: ``BikeError/bikeNotSupported`` if the requested bike model is not supported.
    /// - Throws: ``BluetoothError/timeout`` if the bike could not be found via bluetooth in the specified time period.
    /// - Throws: ``BluetoothError/poweredOff`` if bluetooth is currently switched off.
    /// - Throws: ``BluetoothError/unauthorized`` if the app is not authorized to use bluetooth in the app settings.
    /// - Throws: ``BluetoothError/unsupported`` if your device does not support bluetooth.
    public convenience init (username: String, password: String, apiUrl: URL = VanMoof.Api.url, apiKey: String = VanMoof.Api.key) async throws {
        let api = VanMoof(apiUrl: apiUrl, apiKey: apiKey)
        try await api.authenticate(username: username, password: password)
        guard let details = try await api.bikeDetails().first else {
            throw VanMoofError.noSupportedBikesFound
        }
        try await self.init(scanningForBikeMatchingDetails: details)
    }
}
