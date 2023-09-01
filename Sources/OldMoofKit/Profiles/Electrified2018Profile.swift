//
//  Electrivied2018Profile.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 09.08.23.
//

import CoreBluetooth

struct Electified2018Profile: Profile {
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
        static let setSound: UInt8 = 6 // pairRemote?
        static let setUnit: UInt8 = 7
//        static let showFirmware: UInt8 = 8 ????
//        static let resetDistance: UInt8 = 9 !!
//        static let enableErrors: UInt8 = 0xa ????
        static let setBackupCode: UInt8 = 0xb
//        static let setOffroadMode: UInt8 = 0xc
//        static let firmwareUpdate: UInt8 = 0xd
        static let setAlarm: UInt8 = 0x0f
    }

    let model: String = "S/X2"
    let identifier: CBUUID = Service.Bike.identifier
    let hardware: Hardware = [ .motor, .elock, .speaker ]

    func createChallengeReadRequest() -> ReadRequest<Data> {
        return ReadRequest(uuid: Service.Bike.challenge, decrypt: false) {
            return $0
        }
    }
    func createAuthenticationWriteRequest (key: Data) -> WriteRequest {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setPasscode, data: Data(key[0...11]))
    }

    func createParametersReadRequest () -> ReadRequest<Parameters>? {
        return ReadRequest(uuid: Service.Bike.parameters, decrypt: true) { data in
            guard let data = data else {
                return nil
            }

            let isTracking = (data[2] & 16) != 0
            let isSleeping = (data[2] & 32) != 0
            var moduleState: ModuleState = .standby

            if data[2] & 1 == 1 {
                moduleState = .on
            } else if isTracking {
                moduleState = .tracking
            } else if isSleeping {
                moduleState = .sleeping
            }

            let alarm: Alarm = Alarm(rawValue: (data[2] & 14) >> 1) ?? .automatic
            let isLocked: Lock = data[3] & 2 == 2 ? .locked : .unlocked
            let speed: Int = Int(data[4])
            let motorBatteryLevel: Int = Int(data[5])
            let moduleBatteryLevel: Int = Int(data[6])
            let lighting: Lighting = Lighting(rawValue: data[7] & 3) ?? .off
            let unit: Unit = Unit(rawValue: (data[7] & 4) >> 2) ?? .metric
            let motorAssistance: MotorAssistance = MotorAssistance(rawValue: (data[8] & 0x1C) >> 2) ?? .off
            let region: Region = Region(rawValue: data[8] & 3) ?? .offroad
            let mutedSounds: MutedSounds = MutedSounds(rawValue: UInt16(data[10]) << 6)
            let distance: Double = Double(data[11...14].uint32) / 10.0
            let errorCode: ErrorCode = ErrorCode(code: (data[15] & 0xF8) >> 3)
            let isCharging: BatteryState = (data[15] & 0x01) == 0x01 ? .charging : .discharging
            // 02: 010 -> oben ab
            // 06  110 -> oben ab, lädt nicht mehr
            // 05: 101 -> Laden

            return Parameters(data: data,
                              alarm: alarm,
                              moduleState: moduleState,
                              lock: isLocked,
                              batteryState: isCharging,
                              speed: speed,
                              motorBatteryLevel: motorBatteryLevel,
                              moduleBatteryLevel: moduleBatteryLevel,
                              lighting: lighting,
                              unit: unit,
                              motorAssistance: motorAssistance,
                              region: region,
                              mutedSounds: mutedSounds,
                              distance: distance,
                              errorCode: errorCode)
        }
    }

    func createLockWriteRequest (value: Lock) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.requestLock, data: Data([value.rawValue]))
    }
    func createAlarmWriteRequest (value: Alarm) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setAlarm, data: Data([value.rawValue]))
    }
    func createLightingWriteRequest (value: Lighting) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setLightning, data: Data([value.rawValue]))
    }
    func createMotorAssistanceWriteRequest (value: MotorAssistance, region: Region) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setMotorAssistance, data: Data([value.rawValue, region.rawValue]))
    }
    func createMutedSoundsWriteRequest (value: MutedSounds) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setSound, data: Data([ 0x00, UInt8(value.rawValue >> 6) ]))
    }
    func createModuleStateWriteRequest (value: ModuleState) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setModuleState, data: Data([value.rawValue]))
    }
    func createBackupCodeWriteRequest (code: Int) -> WriteRequest? {
        let data = Data(String(code, radix: 10).map { UInt8($0.wholeNumberValue!) })
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setBackupCode, data: data)
    }
    func createUnitWriteRequest(value: Unit) -> WriteRequest? {
        return WriteRequest(uuid: Service.Bike.functions, command: Command.setUnit, data: Data([value.rawValue]))
    }
}
