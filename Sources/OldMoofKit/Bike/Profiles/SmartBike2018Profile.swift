//
//  SmartBike2019Profile.swift
//  VanMoofTest
//
//  Created by Sebastian Boettcher on 08.08.23.
//

import CoreBluetooth

struct SmartBike2018Profile: BikeProfile {
    struct Service {
        struct Default {
            static let identifier = CBUUID(string: "1800")
            static let batteryLevel = CBUUID(string: "2A19")
            static let batteryPowerState = CBUUID(string: "2A1A")
            static let deviceName = CBUUID(string: "2A00")
        }

        struct Security {
            static let identifier = CBUUID(string: "6ACB5520-E631-4069-944D-B8CA7598AD50")
            // static let unknown = CBUUID(string: "6ACB5521-E631-4069-944D-B8CA7598AD50") // W
            static let challenge = CBUUID(string: "6ACB5522-E631-4069-944D-B8CA7598AD50") // R
            static let passcode = CBUUID(string: "6ACB5523-E631-4069-944D-B8CA7598AD50") // W
            // static let encryptionKey = CBUUID(string: "6ACB5524-E631-4069-944D-B8CA7598AD50") // WN
            // static let distributionKey = CBUUID(string: "6ACB5525-E631-4069-944D-B8CA7598AD50") // WN
        }

        struct Setting {
            static let identifier = CBUUID(string: "6ACB5510-E631-4069-944D-B8CA7598AD50")
            static let light = CBUUID(string: "6ACB5511-E631-4069-944D-B8CA7598AD50") // RWN
            static let alarm = CBUUID(string: "6ACB5512-E631-4069-944D-B8CA7598AD50") // RWN
            // static let wheelSize = CBUUID(string: "6ACB5513-E631-4069-944D-B8CA7598AD50") // RWN
            // static let lightSensor = CBUUID(string: "6ACB5514-E631-4069-944D-B8CA7598AD50") // RN
            static let backupCode = CBUUID(string: "6ACB5515-E631-4069-944D-B8CA7598AD50") // W
        }

        struct Command {
            static let identifier = CBUUID(string: "6ACB5500-E631-4069-944D-B8CA7598AD50")
            static let lock = CBUUID(string: "6ACB5501-E631-4069-944D-B8CA7598AD50") // RWN
            static let distance = CBUUID(string: "6ACB5502-E631-4069-944D-B8CA7598AD50") // RWN
            static let speed = CBUUID(string: "6ACB5503-E631-4069-944D-B8CA7598AD50") // RN
            // static let gSensor = CBUUID(string: "6ACB5504-E631-4069-944D-B8CA7598AD50") // RN
            static let sounds = CBUUID(string: "6ACB5505-E631-4069-944D-B8CA7598AD50") // RWN
            // static let transfer = CBUUID(string: "6ACB5506-E631-4069-944D-B8CA7598AD50") // W
            static let moduleState = CBUUID(string: "6ACB5507-E631-4069-944D-B8CA7598AD50") // RWN
            static let errorCode = CBUUID(string: "6ACB5508-E631-4069-944D-B8CA7598AD50") // RN 0008000008000000af000000b821002044000011
            // static let unknown = CBUUID(string: "6ACB5509-E631-4069-944D-B8CA7598AD50") // W
        }

        // struct Upload {
        //     static let identifier = CBUUID(string: "6ACB5530-E631-4069-944D-B8CA7598AD50")
        //     static let metadata = CBUUID(string: "6ACB5531-E631-4069-944D-B8CA7598AD50") // W
        //     static let firmware = CBUUID(string: "6ACB5532-E631-4069-944D-B8CA7598AD50") // W
        //     static let sound = CBUUID(string: "6ACB5533-E631-4069-944D-B8CA7598AD50") // W
        // }
    }

    let model: String = "SmartS/X"
    let identifier: CBUUID = CBUUID(string: "F0005500-0451-4000-B000-000000000000")
    let hardware: BikeHardware = [ .alarm, .speaker ]

    func makeChallengeReadRequest() -> ReadRequest<Data> {
        return ReadRequest(uuid: Service.Security.challenge, decrypt: false) {
            return $0
        }
    }
    func makeAuthenticationWriteRequest (key: Data) -> WriteRequest {
        return WriteRequest(uuid: Service.Security.passcode, command: nil, data: Data(key[0...11]))
    }

    func makeLockReadRequest () -> ReadRequest<Lock>? {
        return ReadRequest(uuid: Service.Command.lock, decrypt: false) { data in
            (data?.first ?? 1) != 0 ? .locked : .unlocked
        }
    }
    func makeAlarmReadRequest () -> ReadRequest<Alarm>? {
        return ReadRequest(uuid: Service.Setting.alarm, decrypt: false) { data in
            return Alarm(rawValue: data?.first ?? 0) ?? .off
        }
    }
    func makeLightingReadRequest () -> ReadRequest<Lighting>? {
        return ReadRequest(uuid: Service.Setting.light, decrypt: false) { data in
            return Lighting(rawValue: data?.first ?? 0) ?? .automatic
        }
    }
    func makeBatteryLevelReadRequest () -> ReadRequest<Int>? {
        return ReadRequest(uuid: Service.Default.batteryLevel, decrypt: false) { data in
            return Int(data?.first ?? 0)
        }
    }
    func makeBatteryStateReadRequest () -> ReadRequest<BatteryState>? {
        return ReadRequest(uuid: Service.Default.batteryPowerState, decrypt: false) { data in
            // bits 76: overall battery level
            // bits 54: charging state
            // bits 32: discharging state
            // bits 10: battery presence
            return (((data?.first ?? 0) & 0x30) == 0x30) ? .charging : .discharging
        }
    }
    func makeModuleStateReadRequest () -> ReadRequest<ModuleState>? {
        return ReadRequest(uuid: Service.Command.moduleState, decrypt: false) { data in
            return ModuleState(rawValue: data?.first ?? 0) ?? .off
        }
    }
    func makeErrorCodeReadRequest () -> ReadRequest<ErrorCode>? {
        return ReadRequest(uuid: Service.Command.errorCode, decrypt: false) { data in
            return ErrorCode(rawData: data ?? Data())
        }
    }
    func makeMuteSoundReadRequest () -> ReadRequest<MutedSounds>? {
        return ReadRequest(uuid: Service.Command.sounds, decrypt: false) { data in
            let muted = ((UInt16(data?[2] ?? 0) & 0x33) << 8) | (UInt16(data?[3] ?? 0) & 0x33)
            return MutedSounds(rawValue: muted)
        }
    }
    func makeSpeedReadRequest () -> ReadRequest<Int>? {
        return ReadRequest(uuid: Service.Command.speed, decrypt: false) { data in
            return Int(data?.first ?? 0)
        }
    }
    func makeDistanceReadRequest () -> ReadRequest<Double>? {
        return ReadRequest(uuid: Service.Command.distance, decrypt: false) { data in
            return Double(data?.uint32 ?? 0) / 10.0
        }
    }

    func makeLockWriteRequest (value: Lock) -> WriteRequest? {
        return WriteRequest(uuid: Service.Command.lock, command: nil, data: Data([value.rawValue]))
    }
    func makeAlarmWriteRequest (value: Alarm) -> WriteRequest? {
        return WriteRequest(uuid: Service.Setting.alarm, command: nil, data: Data([value.rawValue]))
    }
    func makeLightingWriteRequest (value: Lighting) -> WriteRequest? {
        return WriteRequest(uuid: Service.Setting.light, command: nil, data: Data([value.rawValue]))
    }
    func makeMutedSoundsWriteRequest (value: MutedSounds) -> WriteRequest? {
        let mutedHi = UInt8(value.rawValue >> 8)
        let mutedLo = UInt8(value.rawValue & 0xFF)
        return WriteRequest(uuid: Service.Command.sounds, command: nil, data: Data([ 0x00, 0x00, 0x00, mutedHi, mutedLo ]))
    }
    func makePlaySoundWriteRequest (sound: Sound, repeats count: UInt8) -> WriteRequest? {
        let data = Data([sound.rawValue, 0x00, 0x00, 0x00, count])
        return WriteRequest(uuid: Service.Command.sounds, command: nil, data: data)
    }
    func makeModuleStateWriteRequest (value: ModuleState) -> WriteRequest? {
        return WriteRequest(uuid: Service.Command.moduleState, command: nil, data: Data([value.rawValue]))
    }
    func makeBackupCodeWriteRequest (code: Int) -> WriteRequest? {
        let data = Data(String(code, radix: 10).map { UInt8($0.wholeNumberValue!) })
        return WriteRequest(uuid: Service.Setting.backupCode, command: nil, data: data)
    }
}
