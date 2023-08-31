import CoreBluetooth

protocol Profile {
    var model: String { get }
    var identifier: CBUUID { get }
    var hardware: Hardware { get }

    func createChallengeReadRequest () -> BikeConnection.ReadRequest<Data>
    func createAuthenticationWriteRequest (key: Data) -> BikeConnection.WriteRequest

    func createLockReadRequest () -> BikeConnection.ReadRequest<Lock>?
    func createAlarmReadRequest () -> BikeConnection.ReadRequest<Alarm>?
    func createLightingReadRequest () -> BikeConnection.ReadRequest<Lighting>?
    func createBatteryLevelReadRequest () -> BikeConnection.ReadRequest<Int>?
    func createBatteryStateReadRequest () -> BikeConnection.ReadRequest<BatteryState>?
    func createModuleStateReadRequest () -> BikeConnection.ReadRequest<ModuleState>?
    func createErrorCodeReadRequest () -> BikeConnection.ReadRequest<ErrorCode>?
    func createMuteSoundReadRequest () -> BikeConnection.ReadRequest<MutedSounds>?
    func createSpeedReadRequest () -> BikeConnection.ReadRequest<Int>?
    func createDistanceReadRequest () -> BikeConnection.ReadRequest<Double>?
    func createParametersReadRequest () -> BikeConnection.ReadRequest<Parameters>?

    func createLockWriteRequest (value: Lock) -> BikeConnection.WriteRequest?
    func createAlarmWriteRequest (value: Alarm) -> BikeConnection.WriteRequest?
    func createLightingWriteRequest (value: Lighting) -> BikeConnection.WriteRequest?
    func createMotorAssistanceWriteRequest (value: MotorAssistance, region: Region) -> BikeConnection.WriteRequest?
    func createMutedSoundsWriteRequest (value: MutedSounds) -> BikeConnection.WriteRequest?
    func createPlaySoundWriteRequest (sound: Sound, repeats: UInt8) -> BikeConnection.WriteRequest?
    func createModuleStateWriteRequest (value: ModuleState) -> BikeConnection.WriteRequest?
    func createBackupCodeWriteRequest (code: Int) -> BikeConnection.WriteRequest?
    func createUnitWriteRequest (value: Unit) -> BikeConnection.WriteRequest?
}

extension Profile {
    func createLockReadRequest () -> BikeConnection.ReadRequest<Lock>? {
        return nil
    }
    func createAlarmReadRequest () -> BikeConnection.ReadRequest<Alarm>? {
        return nil
    }
    func createLightingReadRequest () -> BikeConnection.ReadRequest<Lighting>? {
        return nil
    }
    func createBatteryLevelReadRequest () -> BikeConnection.ReadRequest<Int>? {
        return nil
    }
    func createBatteryStateReadRequest () -> BikeConnection.ReadRequest<BatteryState>? {
        return nil
    }
    func createModuleStateReadRequest () -> BikeConnection.ReadRequest<ModuleState>? {
        return nil
    }
    func createErrorCodeReadRequest () -> BikeConnection.ReadRequest<ErrorCode>? {
        return nil
    }
    func createMuteSoundReadRequest () -> BikeConnection.ReadRequest<MutedSounds>? {
        return nil
    }
    func createSpeedReadRequest () -> BikeConnection.ReadRequest<Int>? {
        return nil
    }
    func createDistanceReadRequest () -> BikeConnection.ReadRequest<Double>? {
        return nil
    }
    func createParametersReadRequest () -> BikeConnection.ReadRequest<Parameters>? {
        return nil
    }

    func createLockWriteRequest (value: Lock) -> BikeConnection.WriteRequest? {
        return nil
    }
    func createAlarmWriteRequest (value: Alarm) -> BikeConnection.WriteRequest? {
        return nil
    }
    func createLightingWriteRequest (value: Lighting) -> BikeConnection.WriteRequest? {
        return nil
    }
    func createMotorAssistanceWriteRequest (value: MotorAssistance, region: Region) -> BikeConnection.WriteRequest? {
        return nil
    }
    func createMutedSoundsWriteRequest (value: MutedSounds) -> BikeConnection.WriteRequest? {
        return nil
    }
    func createPlaySoundWriteRequest (sound: Sound, repeats count: UInt8) -> BikeConnection.WriteRequest? {
        return nil
    }
    func createBackupCodeWriteRequest (code: Int) -> BikeConnection.WriteRequest? {
        return nil
    }
    func createUnitWriteRequest(value: Unit) -> BikeConnection.WriteRequest? {
        return nil
    }
}
