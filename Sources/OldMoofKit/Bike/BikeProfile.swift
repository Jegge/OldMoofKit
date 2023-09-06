import CoreBluetooth

protocol BikeProfile {
    var model: String { get }
    var identifier: CBUUID { get }
    var hardware: BikeHardware { get }

    func makeChallengeReadRequest () -> ReadRequest<Data>
    func makeAuthenticationWriteRequest (key: Data) -> WriteRequest

    func makeLockReadRequest () -> ReadRequest<Lock>?
    func makeAlarmReadRequest () -> ReadRequest<Alarm>?
    func makeLightingReadRequest () -> ReadRequest<Lighting>?
    func makeBatteryLevelReadRequest () -> ReadRequest<Int>?
    func makeBatteryStateReadRequest () -> ReadRequest<BatteryState>?
    func makeModuleStateReadRequest () -> ReadRequest<ModuleState>?
    func makeErrorCodeReadRequest () -> ReadRequest<ErrorCode>?
    func makeMuteSoundReadRequest () -> ReadRequest<MutedSounds>?
    func makeSpeedReadRequest () -> ReadRequest<Int>?
    func makeDistanceReadRequest () -> ReadRequest<Double>?
    func makeParametersReadRequest () -> ReadRequest<Parameters>?

    func makeLockWriteRequest (value: Lock) -> WriteRequest?
    func makeAlarmWriteRequest (value: Alarm) -> WriteRequest?
    func makeLightingWriteRequest (value: Lighting) -> WriteRequest?
    func makeMotorAssistanceWriteRequest (value: MotorAssistance, region: Region) -> WriteRequest?
    func makeMutedSoundsWriteRequest (value: MutedSounds) -> WriteRequest?
    func makePlaySoundWriteRequest (sound: Sound, repeats: UInt8) -> WriteRequest?
    func makeModuleStateWriteRequest (value: ModuleState) -> WriteRequest?
    func makeBackupCodeWriteRequest (code: Int) -> WriteRequest?
    func makeUnitWriteRequest (value: Unit) -> WriteRequest?
}

extension BikeProfile {
    func makeLockReadRequest () -> ReadRequest<Lock>? {
        return nil
    }
    func makeAlarmReadRequest () -> ReadRequest<Alarm>? {
        return nil
    }
    func makeLightingReadRequest () -> ReadRequest<Lighting>? {
        return nil
    }
    func makeBatteryLevelReadRequest () -> ReadRequest<Int>? {
        return nil
    }
    func makeBatteryStateReadRequest () -> ReadRequest<BatteryState>? {
        return nil
    }
    func makeModuleStateReadRequest () -> ReadRequest<ModuleState>? {
        return nil
    }
    func makeErrorCodeReadRequest () -> ReadRequest<ErrorCode>? {
        return nil
    }
    func makeMuteSoundReadRequest () -> ReadRequest<MutedSounds>? {
        return nil
    }
    func makeSpeedReadRequest () -> ReadRequest<Int>? {
        return nil
    }
    func makeDistanceReadRequest () -> ReadRequest<Double>? {
        return nil
    }
    func makeParametersReadRequest () -> ReadRequest<Parameters>? {
        return nil
    }

    func makeLockWriteRequest (value: Lock) -> WriteRequest? {
        return nil
    }
    func makeAlarmWriteRequest (value: Alarm) -> WriteRequest? {
        return nil
    }
    func makeLightingWriteRequest (value: Lighting) -> WriteRequest? {
        return nil
    }
    func makeMotorAssistanceWriteRequest (value: MotorAssistance, region: Region) -> WriteRequest? {
        return nil
    }
    func makeMutedSoundsWriteRequest (value: MutedSounds) -> WriteRequest? {
        return nil
    }
    func makePlaySoundWriteRequest (sound: Sound, repeats count: UInt8) -> WriteRequest? {
        return nil
    }
    func makeBackupCodeWriteRequest (code: Int) -> WriteRequest? {
        return nil
    }
    func makeUnitWriteRequest(value: Unit) -> WriteRequest? {
        return nil
    }
}
