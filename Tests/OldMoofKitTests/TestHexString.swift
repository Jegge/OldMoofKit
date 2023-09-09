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
}
