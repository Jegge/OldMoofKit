//
//  TestStringValidation.swift
//  
//
//  Created by Sebastian Boettcher on 07.09.23.
//

import XCTest
@testable import OldMoofKit

final class TestStringValidation: XCTestCase {
    func testValidateMacAddress () {
        XCTAssertFalse("".isValidMacAddress)
        XCTAssertFalse("abcdef".isValidMacAddress)
        XCTAssertFalse("a:c:B:d:e:d".isValidMacAddress)
        XCTAssertFalse("xx:yy:zz:aa:bb:cc".isValidMacAddress)
        XCTAssertTrue("aa:bb:cc:dd:ee:ff".isValidMacAddress)
        XCTAssertTrue("aa-bb-cc-dd-ee-ff".isValidMacAddress)
    }

    func testValidateEncryptionKey () {
        XCTAssertFalse("".isValidEncryptionKey)
        XCTAssertFalse("abcdef".isValidEncryptionKey)
        XCTAssertFalse("00112233445566778899aabbccddeefff".isValidEncryptionKey)
        XCTAssertFalse("00112233445566778899aabbccddeef".isValidEncryptionKey)
        XCTAssertFalse("00112233445566778899aabbccddeefg".isValidEncryptionKey)
        XCTAssertTrue("00000000000000000000000000000000".isValidEncryptionKey)
        XCTAssertTrue("00112233445566778899aabbccddeeff".isValidEncryptionKey)
    }
}
