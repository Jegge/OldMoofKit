//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 07.09.23.
//

import XCTest
@testable import OldMoofKit

final class TestEncryption: XCTestCase {
    func testEncryptionDecryptRoundtrip () {
        let plain = Data([0xde, 0xad, 0xbe, 0xef, 0xc0, 0xff, 0xee, 0x8b, 0xad, 0xf0, 0x0d])
        let key = Data([0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66])
        let encrypted = try! plain.encrypt_aes_ecb_zero(key: key)
        let decrpyted = try! encrypted.decrypt_aes_ecb_zero(key: key)
        XCTAssertEqual(Data([0x6d, 0x57, 0x30, 0x16, 0xbc, 0xe6, 0x83, 0xcb, 0xa2, 0xbf, 0xbf, 0x09, 0xe8, 0xe2, 0x34, 0x50]), encrypted)
        XCTAssertEqual(Data([0xde, 0xad, 0xbe, 0xef, 0xc0, 0xff, 0xee, 0x8b, 0xad, 0xf0, 0x0d, 0x00, 0x00, 0x00, 0x00, 0x00]), decrpyted)
    }

    func testInvalidKeySize () {
        let plain = Data([0xde, 0xad, 0xbe, 0xef, 0xc0, 0xff, 0xee, 0x8b, 0xad, 0xf0, 0x0d])
        let keyShort = Data([0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65])
        let keyLong = Data([0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67])
        XCTAssertThrowsError(try plain.encrypt_aes_ecb_zero(key: keyShort)) { error in
            XCTAssertEqual(error as! CCryptError, CCryptError.keySize)

        }
        XCTAssertThrowsError(try plain.encrypt_aes_ecb_zero(key: keyLong)) { error in
            XCTAssertEqual(error as! CCryptError, CCryptError.keySize)
        }
    }
}
