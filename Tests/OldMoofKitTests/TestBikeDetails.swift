//
//  TestBikeDetails.swift
//  
//
//  Created by Sebastian Boettcher on 09.09.23.
//

import XCTest

@testable import OldMoofKit

final class TestBikeDetails: XCTestCase {

    let bleProfile = BikeProfileName.smartBike2018
    let macAddress = "1a:2b:3c:4d:5e:6f"
    let encryptionKey = "4142434445464748494a4b4c4d4e4f50" // "ABCDEFGHIJKLMNOP"
    let bikeName = "MyBikeName"
    let frameNumber = "ACAB1312"
    let modelName = "Das Modell"
    let smartModuleVersion = "1.23.42"

    func testBikeDetailsValidSupported () throws {
        let details = try BikeDetails(bleProfile: bleProfile,
                                      macAddress: macAddress,
                                      encryptionKey: encryptionKey,
                                      name: bikeName,
                                      frameNumber: frameNumber,
                                      modelName: modelName,
                                      smartModuleVersion: smartModuleVersion)

        XCTAssertEqual(details.bleProfile, bleProfile)
        XCTAssertEqual(details.macAddress, macAddress)
        XCTAssertEqual(details.encryptionKey, encryptionKey)
        XCTAssertEqual(details.name, bikeName)
        XCTAssertEqual(details.model, SmartBike2018Profile().model)
        XCTAssertEqual(details.modelName, modelName)
        XCTAssertEqual(details.frameNumber, frameNumber)
        XCTAssertEqual(details.smartModuleVersion, smartModuleVersion)
        XCTAssertNotNil(details.profile)
        XCTAssertEqual(details.hardware, SmartBike2018Profile().hardware)
        XCTAssertTrue(details.isSupported)
        XCTAssertEqual(details.deviceName, "VANMOOF-4d5e6f")
    }

    func testBikeDetailsValidUnsupported () throws {
        let details = try BikeDetails(bleProfile: .electrified2022,
                                      macAddress: macAddress,
                                      encryptionKey: encryptionKey,
                                      name: bikeName,
                                      frameNumber: frameNumber,
                                      modelName: modelName,
                                      smartModuleVersion: smartModuleVersion)

        XCTAssertEqual(details.bleProfile, .electrified2022)
        XCTAssertEqual(details.macAddress, macAddress)
        XCTAssertEqual(details.encryptionKey, encryptionKey)
        XCTAssertEqual(details.name, bikeName)
        XCTAssertEqual(details.model, modelName)
        XCTAssertEqual(details.modelName, modelName)
        XCTAssertEqual(details.frameNumber, frameNumber)
        XCTAssertEqual(details.smartModuleVersion, smartModuleVersion)
        XCTAssertNil(details.profile)
        XCTAssertEqual(details.hardware, [])
        XCTAssertFalse(details.isSupported)
        XCTAssertEqual(details.deviceName, "VANMOOF-4d5e6f")
    }

    func testBikeDetailsInvalidMacAddress () throws {
        XCTAssertThrowsError(try BikeDetails(bleProfile: bleProfile, macAddress: "cxfgrt576xfg", encryptionKey: encryptionKey)) { error in
            XCTAssertEqual(error as! BikeError, BikeError.macAddressInvalidFormat)
        }
    }

    func testBikeDetailsInvalidEncryptionKey () throws {
        XCTAssertThrowsError(try BikeDetails(bleProfile: bleProfile, macAddress: macAddress, encryptionKey: "fsadf")) { error in
            XCTAssertEqual(error as! BikeError, BikeError.encryptionKeyInvalidFormat)
        }
    }
}
