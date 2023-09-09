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
        static let name = "MyBikeName"
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

        var notificationPublisher = PassthroughSubject<BluetoothNotification, Never>()
        var errorPublisher = PassthroughSubject<Error, Never>()
        var statePublisher = PassthroughSubject<BluetoothState, Never>()

        var identifier: UUID = UUID(uuidString: "5d98872f-ab56-4b2c-96b5-254d45202857")!
        var reconnectInterval: TimeInterval = 0.0
        var state: BluetoothState = .disconnected

        func connect() async throws {
            self.state = .connected
            self.statePublisher.send(.connected)
        }

        func disconnect() {
            self.state = .disconnected
            self.statePublisher.send(.disconnected)
        }

        func writeValue(_ data: Data, for uuid: CBUUID) async throws {
            self.handleWriteValue?(data, uuid, self.notificationPublisher)
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

    func testBikeConnection() async throws {
        let bluetooth = SmartBike2018BluetoothConnectionMock()
        var authenticated = 0
        var setLight = false
        var setLock = false
        var setAlarm = false
        var setModuleState = false
        var setMutedSounds = false

        bluetooth.handleWriteValue = { data, uuid, notifications in
            let payload = Data(try! data.decrypt_aes_ecb_zero(key: Data(hexString: SmartBike2018BluetoothConnectionMock.encryptionKey)!).dropFirst(2))
            switch uuid.uuidString {
            case "6ACB5523-E631-4069-944D-B8CA7598AD50": // write passcode
                XCTAssertEqual("1dcb5f2321fe1ee12a616ad62c6bdde2", data.hexString, "Bike authentication failed")
                authenticated += 1

            case "6ACB5511-E631-4069-944D-B8CA7598AD50": // set light
                XCTAssertEqual(Lighting(rawValue: payload.first!)!, .alwaysOn)
                notifications.send(BluetoothNotification(uuid: uuid, data: Data([Lighting.alwaysOn.rawValue])))
                setLight = true

            case "6ACB5501-E631-4069-944D-B8CA7598AD50": // set lock
                XCTAssertEqual(Lock(rawValue: payload.first!)!, .unlocked)
                notifications.send(BluetoothNotification(uuid: uuid, data: Data([Lock.unlocked.rawValue])))
                setLock = true

            case "6ACB5512-E631-4069-944D-B8CA7598AD50": // set alarm
                XCTAssertEqual(Alarm(rawValue: payload.first!)!, .manual)
                notifications.send(BluetoothNotification(uuid: uuid, data: Data([Alarm.manual.rawValue])))
                setAlarm = true

            case "6ACB5507-E631-4069-944D-B8CA7598AD50": // set module state
                XCTAssertEqual(ModuleState(rawValue: payload.first!)!, .on)
                notifications.send(BluetoothNotification(uuid: uuid, data: Data([ModuleState.on.rawValue])))
                setModuleState = true

            case "6ACB5505-E631-4069-944D-B8CA7598AD50": // set muted sounds
                XCTAssertEqual(Data(hexString: "0000003300000000000000000000"), payload)
                notifications.send(BluetoothNotification(uuid: uuid, data: Data([0x00, 0x00, 0x33, 0x00])))
                setMutedSounds = true 

            default:
                break
            }
        }

        bluetooth.handleReadValue = { uuid in
            switch uuid.uuidString {
            case "6ACB5522-E631-4069-944D-B8CA7598AD50": // read challenge
                return Data([0x23, 0x42])
            case "6ACB5511-E631-4069-944D-B8CA7598AD50": // read light
                return Data([Lighting.off.rawValue])
            case "6ACB5501-E631-4069-944D-B8CA7598AD50":  // read lock
                return Data([Lock.locked.rawValue])
            case "6ACB5512-E631-4069-944D-B8CA7598AD50": // read alarm
                return Data([Alarm.automatic.rawValue])
            case "6ACB5502-E631-4069-944D-B8CA7598AD50": // read distance
                return Data([12,34,56,78]) // 131230158.0 km
            case "6ACB5507-E631-4069-944D-B8CA7598AD50": // read module state
                return Data([ModuleState.standby.rawValue])
            case "6ACB5508-E631-4069-944D-B8CA7598AD50": // read error code
                return Data([0x23, 0x42])
            case "6ACB5505-E631-4069-944D-B8CA7598AD50": // read muted sounds
                return Data([0x00, 0x00, 0x00, 0x00])

            default:
                return nil
            }
        }

        let bluetoothErrors = bluetooth.errorPublisher.sink { error in
            XCTFail("Bluetooth error: \(error)")
        }

        let details = try BikeDetails(bleProfile: .smartBike2018,
                                      macAddress: SmartBike2018BluetoothConnectionMock.macAddress,
                                      encryptionKey: SmartBike2018BluetoothConnectionMock.encryptionKey,
                                      name: SmartBike2018BluetoothConnectionMock.name,
                                      frameNumber: SmartBike2018BluetoothConnectionMock.frameNumber,
                                      modelName: SmartBike2018BluetoothConnectionMock.modelName,
                                      smartModuleVersion: SmartBike2018BluetoothConnectionMock.smartModuleVersion)

        let bike = try await Bike(scanner: bluetooth, details: details, profile: details.profile!)

        XCTAssertEqual(bike.details, details)

        let bikeErrors = bike.errorPublisher.sink { error in
            XCTFail("Bluetooth error: \(error)")
        }

        XCTAssertEqual(bike.state, .disconnected)
        try await bike.connect()
        XCTAssertEqual(bike.state, .connected)
        XCTAssertEqual(authenticated, 1)

        XCTAssertEqual(bike.distance, 131230158.0)
        XCTAssertEqual(bike.moduleState, .standby)
        XCTAssertEqual(bike.errorCode.data, Data([0x23, 0x42]))
        XCTAssertEqual(bike.lighting, .off)
        XCTAssertEqual(bike.lock, .locked)
        XCTAssertEqual(bike.alarm, .automatic)
        XCTAssertEqual(bike.mutedSounds, .none)

        try await bike.wakeup()
        while !setModuleState { try await Task.sleep(nanoseconds: NSEC_PER_SEC >> 2) } // this is a dirty hack. do not use this in production code!
        XCTAssertEqual(bike.moduleState, .on)

        try await bike.set(lighting: .alwaysOn)
        while !setLight { try await Task.sleep(nanoseconds: NSEC_PER_SEC >> 2) }
        XCTAssertEqual(bike.lighting, .alwaysOn)

        try await bike.set(lock: .unlocked)
        while !setLock { try await Task.sleep(nanoseconds: NSEC_PER_SEC >> 2) }
        XCTAssertEqual(bike.lock, .unlocked)

        try await bike.set(alarm: .manual)
        while !setAlarm { try await Task.sleep(nanoseconds: NSEC_PER_SEC >> 2) }
        XCTAssertEqual(bike.alarm, .manual)

        try await bike.set(mutedSounds: [.lockState, .moduleState])
        while !setMutedSounds { try await Task.sleep(nanoseconds: NSEC_PER_SEC >> 2) }
        XCTAssertEqual(bike.mutedSounds, [.lockState, .moduleState])

        bike.disconnect()
        XCTAssertEqual(bike.state, .disconnected)

        bluetoothErrors.cancel()
        bikeErrors.cancel()
    }
}
