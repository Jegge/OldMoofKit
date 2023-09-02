import CoreBluetooth

protocol BikeProfile {
    var model: String { get }
    var identifier: CBUUID { get }
    var hardware: BikeHardware { get }

    func createChallengeReadRequest () -> ReadRequest<Data>
    func createAuthenticationWriteRequest (key: Data) -> WriteRequest

    func createLockReadRequest () -> ReadRequest<Lock>?
    func createAlarmReadRequest () -> ReadRequest<Alarm>?
    func createLightingReadRequest () -> ReadRequest<Lighting>?
    func createBatteryLevelReadRequest () -> ReadRequest<Int>?
    func createBatteryStateReadRequest () -> ReadRequest<BatteryState>?
    func createModuleStateReadRequest () -> ReadRequest<ModuleState>?
    func createErrorCodeReadRequest () -> ReadRequest<ErrorCode>?
    func createMuteSoundReadRequest () -> ReadRequest<MutedSounds>?
    func createSpeedReadRequest () -> ReadRequest<Int>?
    func createDistanceReadRequest () -> ReadRequest<Double>?
    func createParametersReadRequest () -> ReadRequest<Parameters>?

    func createLockWriteRequest (value: Lock) -> WriteRequest?
    func createAlarmWriteRequest (value: Alarm) -> WriteRequest?
    func createLightingWriteRequest (value: Lighting) -> WriteRequest?
    func createMotorAssistanceWriteRequest (value: MotorAssistance, region: Region) -> WriteRequest?
    func createMutedSoundsWriteRequest (value: MutedSounds) -> WriteRequest?
    func createPlaySoundWriteRequest (sound: Sound, repeats: UInt8) -> WriteRequest?
    func createModuleStateWriteRequest (value: ModuleState) -> WriteRequest?
    func createBackupCodeWriteRequest (code: Int) -> WriteRequest?
    func createUnitWriteRequest (value: Unit) -> WriteRequest?
}

extension BikeProfile {
    func createLockReadRequest () -> ReadRequest<Lock>? {
        return nil
    }
    func createAlarmReadRequest () -> ReadRequest<Alarm>? {
        return nil
    }
    func createLightingReadRequest () -> ReadRequest<Lighting>? {
        return nil
    }
    func createBatteryLevelReadRequest () -> ReadRequest<Int>? {
        return nil
    }
    func createBatteryStateReadRequest () -> ReadRequest<BatteryState>? {
        return nil
    }
    func createModuleStateReadRequest () -> ReadRequest<ModuleState>? {
        return nil
    }
    func createErrorCodeReadRequest () -> ReadRequest<ErrorCode>? {
        return nil
    }
    func createMuteSoundReadRequest () -> ReadRequest<MutedSounds>? {
        return nil
    }
    func createSpeedReadRequest () -> ReadRequest<Int>? {
        return nil
    }
    func createDistanceReadRequest () -> ReadRequest<Double>? {
        return nil
    }
    func createParametersReadRequest () -> ReadRequest<Parameters>? {
        return nil
    }

    func createLockWriteRequest (value: Lock) -> WriteRequest? {
        return nil
    }
    func createAlarmWriteRequest (value: Alarm) -> WriteRequest? {
        return nil
    }
    func createLightingWriteRequest (value: Lighting) -> WriteRequest? {
        return nil
    }
    func createMotorAssistanceWriteRequest (value: MotorAssistance, region: Region) -> WriteRequest? {
        return nil
    }
    func createMutedSoundsWriteRequest (value: MutedSounds) -> WriteRequest? {
        return nil
    }
    func createPlaySoundWriteRequest (sound: Sound, repeats count: UInt8) -> WriteRequest? {
        return nil
    }
    func createBackupCodeWriteRequest (code: Int) -> WriteRequest? {
        return nil
    }
    func createUnitWriteRequest(value: Unit) -> WriteRequest? {
        return nil
    }
}
