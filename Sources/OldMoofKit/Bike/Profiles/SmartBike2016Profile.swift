//
//  SmartBike2017.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 28.08.23.
//

import CoreBluetooth

struct SmartBike2016Profile: BikeProfile {
    struct Service {
//        struct DeviceInformation {
//            static let identifier = CBUUID(string: "0000180a-0000-1000-8000-00805f9b34fb")
//            static let firmwareRevision = CBUUID(string: "00002a26-0000-1000-8000-00805f9b34fb")
//            static let hardwareRevision = CBUUID(string: "00002a27-0000-1000-8000-00805f9b34fb")
//            static let softwareRevision = CBUUID(string: "00002a28-0000-1000-8000-00805f9b34fb")
//            static let modelNumber = CBUUID(string: "00002a24-0000-1000-8000-00805f9b34fb")
//            static let serialNumber = CBUUID(string: "00002a25-0000-1000-8000-00805f9b34fb")
//        }

//        struct ServiceOAD {
//            static let identifier = CBUUID(string: "f000ffc0-0451-4000-b000-000000000000")
//            static let imageBlock = CBUUID(string: "f000ffc2-0451-4000-b000-000000000000")
//            static let imageCount = CBUUID(string: "f000ffc3-0451-4000-b000-000000000000")
//            static let imageIdentify = CBUUID(string: "f000ffc1-0451-4000-b000-000000000000")
//            static let imageStatus = CBUUID(string: "f000ffc4-0451-4000-b000-000000000000")
//        }

        struct Bike {
            static let identifier = CBUUID(string: "8e7f1a50-087a-44c9-b292-a2c628fdd9aa")
            static let challenge = CBUUID(string: "8e7f1a51-087a-44c9-b292-a2c628fdd9aa")
            // static let passcode = CBUUID(string: "8e7f1a52-087a-44c9-b292-a2c628fdd9aa")
            static let functions = CBUUID(string: "8e7f1a53-087a-44c9-b292-a2c628fdd9aa")
            static let parameters = CBUUID(string: "8e7f1a54-087a-44c9-b292-a2c628fdd9aa")
        }
    }

    struct Command {
        static let setPasscode: UInt8 = 1
        static let setModuleState: UInt8 = 2
        static let requestLock: UInt8 = 3
        static let setMotorAssistance: UInt8 = 4
        static let setLightning: UInt8 = 5
//        static let setPairRemote: UInt8 = 6
        static let setUnit: UInt8 = 7
//        static let showFirmware: UInt8 = 8 ????
//        static let resetDistance: UInt8 = 9 !!
//        static let enableErrors: UInt8 = 0xa ????
//        static let disableErrors: UInt8 = 0xb ????
//        static let setOffroadMode: UInt8 = 0xc
//        static let firmwareUpdate: UInt8 = 0xd
    }

    let model: String = "SmartBike"
    let identifier: CBUUID = Service.Bike.identifier
    let hardware: BikeHardware = [ .elock ]

    func makeChallengeReadRequest() -> ReadRequest<Data> {
        return ReadRequest(uuid: Service.Bike.challenge, decrypt: false) {
            return $0
        }
    }
    func makeAuthenticationWriteRequest (key: Data) -> WriteRequest {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setPasscode, data: Data(key[0...5]))
    }

    func makeParametersReadRequest () -> ReadRequest<Parameters>? {
        return ReadRequest(uuid: Service.Bike.parameters, decrypt: true) { data in
            guard let data = data else {
                return nil
            }

            let moduleState: ModuleState = data[2] == 1 ? .on : .standby
            let isLocked: Lock = data[3] == 1 ? .locked : .unlocked
            let speed: Int = Int(data[4])
            let moduleBatteryLevel: Int = Int(data[6])
            let lighting: Lighting = Lighting(rawValue: data[7]) ?? .off
            let region: Region = Region(rawValue: data[9]) ?? .offroad
            let unit: Unit = Unit(rawValue: data[10]) ?? .metric
            let distance: Double = Double(Data(data[11...14]).uint32) / 10.0
            let errorCode: ErrorCode = ErrorCode(code: (data[15] & 0xF8) >> 3)
            let isCharging: BatteryState = (data[15] & 0x01) == 0x01 ? .charging : .discharging

            return Parameters(data: data,
                              alarm: nil,
                              moduleState: moduleState,
                              lock: isLocked,
                              batteryState: isCharging,
                              speed: speed,
                              motorBatteryLevel: nil,
                              moduleBatteryLevel: moduleBatteryLevel,
                              lighting: lighting,
                              unit: unit,
                              motorAssistance: nil,
                              region: region,
                              mutedSounds: .none,
                              distance: distance,
                              errorCode: errorCode)
        }
    }

    func makeLockWriteRequest (value: Lock) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.requestLock, data: Data([value.rawValue]))
    }
    func makeLightingWriteRequest (value: Lighting) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setLightning, data: Data([value.rawValue]))
    }
    func makeModuleStateWriteRequest (value: ModuleState) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setModuleState, data: Data([value.rawValue]))
    }
//    func createBackupCodeWriteRequest (code: Int) -> WriteRequest? {
//        let data = Data(String(code, radix: 10).map { UInt8($0.wholeNumberValue!) })
//        return WriteRequest(uuid: Service.Bike.functions, command: Command.setBackupCode, data: data)
//    }
    func makeUnitWriteRequest(value: Unit) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setUnit, data: Data([value.rawValue]))
    }
}
