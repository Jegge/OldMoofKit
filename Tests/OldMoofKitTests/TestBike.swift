//
//  TestBike.swift
//  
//
//  Created by Sebastian Boettcher on 08.09.23.
//

import XCTest
import CoreBluetooth
import Combine

@testable import OldMoofKit

final class TestBike: XCTestCase {

    private class SmartBike2018BluetoothConnectionMock: BluetoothConnectionProtocol, BluetoothScannerProtocol {
        static let macAddress = "1a:2b:3c:4d:5e:6f"
        static let encryptionKey = "4142434445464748494a4b4c4d4e4f50" // "ABCDEFGHIJKLMNOP"
        static let frameNumber = "ACAB1312"
        static let modelName = "Das Modell"
        static let smartModuleVersion = "1.23.42"

        var handleWriteValue: ((Data, CBUUID, PassthroughSubject<BluetoothNotification, Never>) -> Void)?
        var handleReadValue: ((CBUUID) -> Data?)?

        func scanForPeripherals(withServices services: [CBUUID]?, name: String?, timeout seconds: TimeInterval) async throws -> UUID {
            return self.identifier
        }

        func makeConnection(identifier: UUID) -> BluetoothConnectionProtocol {
            return self
        }

        var notifications = PassthroughSubject<BluetoothNotification, Never>()
        var errors = PassthroughSubject<Error, Never>()
        var state = PassthroughSubject<BluetoothState, Never>()

        var identifier: UUID = UUID(uuidString: "5d98872f-ab56-4b2c-96b5-254d45202857")!
        var reconnectInterval: TimeInterval = 0.0
        var isConnected: Bool = false

        func connect() async throws {
            self.isConnected = true
            self.state.send(.connected)
        }

        func disconnect() {
            self.isConnected = false
            self.state.send(.disconnected)
        }

        func writeValue(_ data: Data, for uuid: CBUUID) async throws {
            self.handleWriteValue?(data, uuid, self.notifications)
        }

        func readValue(for uuid: CBUUID) async throws -> Data? {
            return self.handleReadValue?(uuid)
        }

        func setNotifyValue(enabled: Bool, for uuid: CBUUID) {
        }

        func readRssi() async throws -> Int {
            return 42
        }
    }

    func testScannedBike() async throws {
        let bluetooth = SmartBike2018BluetoothConnectionMock()
        var testsDone = false
        var authenticated = false
        var setLight = false
        var setLock = false

        bluetooth.handleWriteValue = { data, uuid, notifications in
            let payload = Data(try! data.decrypt_aes_ecb_zero(key: Data(hexString: SmartBike2018BluetoothConnectionMock.encryptionKey)!).dropFirst(2))
            switch uuid.uuidString {
            case "6ACB5523-E631-4069-944D-B8CA7598AD50": // write passcode
                XCTAssertEqual("1dcb5f2321fe1ee12a616ad62c6bdde2", data.hexString, "Bike authentication failed")
                authenticated = true

            case "6ACB5511-E631-4069-944D-B8CA7598AD50": // set light
                XCTAssertEqual(Lighting(rawValue: payload.first!)!, .alwaysOn)
                notifications.send(BluetoothNotification(uuid: uuid, data: Data([Lighting.alwaysOn.rawValue])))
                setLight = true

            case "6ACB5501-E631-4069-944D-B8CA7598AD50": // set lock
                XCTAssertEqual(Lock(rawValue: payload.first!)!, .unlocked)
                notifications.send(BluetoothNotification(uuid: uuid, data: Data([Lock.unlocked.rawValue])))
                setLock = true
                testsDone = true

            default:
                break
            }
        }

        bluetooth.handleReadValue = { uuid in
            switch uuid.uuidString {
            case "6ACB5522-E631-4069-944D-B8CA7598AD50": // read challenge
                return Data(hexString: "2342")
            case "6ACB5511-E631-4069-944D-B8CA7598AD50": // read light
                return Data([Lighting.off.rawValue])
            case "6ACB5501-E631-4069-944D-B8CA7598AD50":  // read lock
                return Data([Lock.locked.rawValue])
            default:
                return nil
            }
        }

        let bluetoothErrors = bluetooth.errors.sink { error in
            XCTFail("Bluetooth error: \(error)")
        }

        let details = try BikeDetails(bleProfile: .smartBike2018,
                                      macAddress: SmartBike2018BluetoothConnectionMock.macAddress,
                                      encryptionKey: SmartBike2018BluetoothConnectionMock.encryptionKey,
                                      frameNumber: SmartBike2018BluetoothConnectionMock.frameNumber,
                                      modelName: SmartBike2018BluetoothConnectionMock.modelName,
                                      smartModuleVersion: SmartBike2018BluetoothConnectionMock.smartModuleVersion)

        let bike = try await Bike(scanner: bluetooth, details: details, profile: details.profile!)

        let bikeErrors = bike.errorPublisher.sink { error in
            XCTFail("Bluetooth error: \(error)")
        }

        XCTAssertEqual(bike.details, details)

        XCTAssertEqual(bike.state, .disconnected)
        try await bike.connect()
        await bike.statePublisher.awaitValue(.connected)
        XCTAssertEqual(bike.state, .connected)
        XCTAssertTrue(authenticated)

        XCTAssertEqual(bike.lighting, .off)
        try await bike.set(lighting: .alwaysOn)
        XCTAssertEqual(bike.lighting, .alwaysOn)
        XCTAssertTrue(setLight)

        XCTAssertEqual(bike.lock, .locked)
        try await bike.set(lock: .unlocked)
        XCTAssertEqual(bike.lock, .unlocked)
        XCTAssertTrue(setLock)

        while !testsDone {
            try await Task.sleep(nanoseconds: NSEC_PER_SEC >> 2)
        }

        bike.disconnect()
        XCTAssertEqual(bike.state, .disconnected)

        bluetoothErrors.cancel()
        bikeErrors.cancel()
    }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher where Self.Failure == Never, Self.Output: Equatable {
    func awaitValue (_ value: Self.Output) async {
        var cancellable: AnyCancellable?
        await withCheckedContinuation { continuation in
            cancellable = self.sink { received in
                if received == value {
                    continuation.resume()
                }
            }
        }
        cancellable?.cancel()
    }
}
