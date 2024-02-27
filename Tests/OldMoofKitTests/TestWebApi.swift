//
//  TestWebApi.swift
//  
//
//  Created by Sebastian Boettcher on 27.02.24.
//

import XCTest

@testable import OldMoofKit

struct Secrets: Decodable {
    let username: String
    let password: String

    static func load() throws -> Self {
        let secretsFileUrl = Bundle.module.url(forResource: "secrets", withExtension: "json")

        guard let secretsFileUrl = secretsFileUrl, let secretsFileData = try? Data(contentsOf: secretsFileUrl) else {
            fatalError("No 'secrets.json' file found. Create a new file based on 'secrets.json.sample' using our credentials.")
        }

        return try JSONDecoder().decode(Self.self, from: secretsFileData)
    }
}

final class TestWebApi: XCTestCase {
//    func testWebApi() async throws {
//        let secrets = try Secrets.load()
//
//        let api = VanMoof(apiUrl: VanMoof.Api.url, apiKey: VanMoof.Api.key)
//        try await api.authenticate(username: secrets.username, password: secrets.password)
//        let (_, details) = try await api.bikeDetails()
//
//        XCTAssertFalse(details.isEmpty)
//    }
}
