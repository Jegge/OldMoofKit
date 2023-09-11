//
//  File.swift
//
//
//  Created by Sebastian Boettcher on 07.09.23.
//

import XCTest
@testable import OldMoofKit

final class TestHexString: XCTestCase {
    func testDataFromHexString() {
        XCTAssertEqual(Data([0xde, 0xad, 0xbe, 0xef, 0xc0, 0xff, 0xee, 0x8b, 0xad, 0xf0, 0x0d]), Data(hexString: "deadbeefc0ffee8badf00d"))
    }
    
    func testHexStringFromData () {
        XCTAssertEqual("deadbeefc0ffee8badf00d", Data([0xde, 0xad, 0xbe, 0xef, 0xc0, 0xff, 0xee, 0x8b, 0xad, 0xf0, 0x0d]).hexString)
    }

    func testHexStringFromDataWithWhitespace() {
        XCTAssertEqual(Data([0xde, 0xad, 0xbe, 0xef, 0xc0, 0xff, 0xee, 0x8b, 0xad, 0xf0, 0x0d]), Data(hexString: "de ad be ef\tc0ff\ree8b\nad f0 0d"))
    }

    func testHexStringFromInvalidData() {
        XCTAssertNil(Data(hexString: "deadbeefc0ffee8badf00de"))
        XCTAssertNil(Data(hexString: "deadbeefc0ffee8badf00Z"))
    }
}

