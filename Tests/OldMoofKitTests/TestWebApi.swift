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

    static func load() throws -> Self? {
        guard let url = Bundle.module.url(forResource: "secrets", withExtension: "json"), let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

final class TestWebApi: XCTestCase {
    func testWebApi() async throws {
        
        let secrets = try Secrets.load()

        try XCTSkipIf(secrets == nil, "No 'secrets.json' file found. Create a new file based on 'secrets.json.sample' using our credentials.")

        let api = VanMoof(apiUrl: VanMoof.Api.url, apiKey: VanMoof.Api.key)
        try await api.authenticate(username: secrets!.username, password: secrets!.password)
        let (_, details) = try await api.bikeDetails()

        XCTAssertFalse(details.isEmpty)
    }
}
