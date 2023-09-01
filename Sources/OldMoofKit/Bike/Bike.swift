//
//  BikeConnection.swift
//  VanMoofTest
//
//  Created by Sebastian Boettcher on 09.08.23.
//

import CoreBluetooth
import Combine

public enum BikeEvent {
    case connected
    case disconnected
    case error(_ error: Error)
    case changedAlarm(_ alarm: Alarm)
    case changedLock(_ lock: Lock)
    case changedLighting(_ lighting: Lighting)
    case changedBatteryLevel(_ level: Int)
    case changedBatteryState(_ state: BatteryState)
    case changedModuleState(_ state: ModuleState)
    case changedErrorCode(_ code: ErrorCode)
    case changedMotorAssistance(_ assistance: MotorAssistance)
    case changedMutedSounds(_ mutedSounds: MutedSounds)
    case changedSpeed(_ speed: Int)
    case changedDistance(_ distance: Double)
    case changedRegion(_ region: Region)
    case changedUnit(_ unit: Unit)
}

public final class Bike: Codable {
    enum CodingKeys: String, CodingKey {
        case identifier
        case properties
        case configuration
    }

    public let identifier: UUID
    public let properties: BikeProperties
    public var configuration: BikeConfiguration

    public let events: PassthroughSubject<BikeEvent, Never> = PassthroughSubject<BikeEvent, Never>()

    private var profile: Profile
    private var connection: BluetoothConnection?
    private var bluetoothEvents: AnyCancellable?

    public var isConnected: Bool {
        return self.connection?.isConnected ?? false
    }

    private (set) public var lock: Lock = .locked {
        didSet {
            self.events.send(.changedLock(self.lock))
        }
    }
    private (set) public var alarm: Alarm? {
        didSet {
            if let alarm = self.alarm {
                self.events.send(.changedAlarm(alarm))
            }
        }
    }
    private (set) public var lighting: Lighting = .off {
        didSet {
            self.events.send(.changedLighting(self.lighting))
        }
    }
    private (set) public var batteryLevel: Int = 0 {
        didSet {
            self.events.send(.changedBatteryLevel(self.batteryLevel))
        }
    }
    private (set) public var batteryState: BatteryState = .discharging {
        didSet {
            self.events.send(.changedBatteryState(self.batteryState))
        }
    }
    private (set) public var moduleState: ModuleState = .off {
        didSet {
            self.events.send(.changedModuleState(self.moduleState))
        }
    }
    private (set) public var errorCode: ErrorCode = ErrorCode() {
        didSet {
            self.events.send(.changedErrorCode(self.errorCode))
        }
    }
    private (set) public var motorAssistance: MotorAssistance? {
        didSet {
            if let motorAssistance = self.motorAssistance {
                self.events.send(.changedMotorAssistance(motorAssistance))
            }
        }
    }
    private (set) public var mutedSounds: MutedSounds = [] {
        didSet {
            self.events.send(.changedMutedSounds(self.mutedSounds))
        }
    }
    private (set) public var speed: Int = 0 {
        didSet {
            self.events.send(.changedSpeed(self.speed))
        }
    }
    private (set) public var distance: Double = 0 {
        didSet {
            self.events.send(.changedDistance(self.distance))
        }
    }
    private (set) public var region: Region? {
        didSet {
            if let region = self.region {
                self.events.send(.changedRegion(region))
            }
        }
    }
    private (set) public var unit: Unit? {
        didSet {
            if let unit = self.unit {
                self.events.send(.changedUnit(unit))
            }
        }
    }

    private init (identifier: UUID, properties: BikeProperties, profile: Profile, configuration: BikeConfiguration) {
        self.identifier = identifier
        self.properties = properties
        self.configuration = configuration
        self.profile = profile
    }

    public convenience init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(UUID.self, forKey: .identifier)
        let properties = try container.decode(BikeProperties.self, forKey: .properties)
        let configuration = try container.decode(BikeConfiguration.self, forKey: .configuration)
        guard let profile = properties.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        self.init(identifier: identifier, properties: properties, profile: profile, configuration: configuration)
    }

    public convenience init (scanningForBikeMatchingProperties properties: BikeProperties, timeout seconds: TimeInterval = 30) async throws {
        guard let profile = properties.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        let scanner = BluetoothScanner()
        let identifier = try await scanner.scanForPeripherals(withServices: [profile.identifier], name: properties.deviceName, timeout: seconds)
        self.init(identifier: identifier, properties: properties, profile: profile, configuration: BikeConfiguration())
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.properties, forKey: .properties)
        try container.encode(self.configuration, forKey: .configuration)
    }

      private func readRequest<T> (_ request: ReadRequest<T>?) async throws -> T? {
        guard let request = request else {
            return nil
        }
        guard let connection = self.connection else {
            throw BikeConnectionError.notConnected
        }

        var data = try await connection.readValue(for: request.uuid)
        if request.decrypt {
            data = try data?.decrypt_aes_ecb_zero(key: self.properties.key)
        }

        return request.parse(data)
    }

    private func writeRequest (_ request: WriteRequest?) async throws {
        guard let request = request else {
            return
        }
        guard let connection = self.connection else {
            throw BikeConnectionError.notConnected
        }

        let challenge = try await self.readRequest(self.profile.createChallengeReadRequest())
        guard var data = challenge?[...1] else {
            return
        }

        if let command = request.command {
            data += Data([command])
        }

        data += request.data

        let payload = try data.encrypt_aes_ecb_zero(key: self.properties.key)
        try await connection.writeValue(payload, for: request.uuid)
    }

    private func notifyRequest<T> (_ request: ReadRequest<T>?, callback: @escaping ((T) -> Void)) throws {
        guard let request = request else {
            return
        }
        guard let connection = self.connection else {
            throw BikeConnectionError.notConnected
        }
        connection.setNotifyValue(enabled: true, for: request.uuid) { data in
            var data = data
            do {
                if request.decrypt {
                    data = try data?.decrypt_aes_ecb_zero(key: self.properties.key)
                }
                if let payload = request.parse(data) {
                    callback(payload)
                }
            } catch {
                self.events.send(.error(error))
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func setupConnection () async throws {
        print("Authenticating...")
        try await self.writeRequest(self.profile.createAuthenticationWriteRequest(key: self.properties.key))

        if self.configuration.proximityUnlock {
            print("Unlocking because of proximity...")
            try await self.setLocked(.unlocked)
        }

        print("Reading parameters...")
        if let parameters = try await self.readRequest(self.profile.createParametersReadRequest()) {
            print("Parameters:\n\(parameters.description)")
            self.batteryLevel = parameters.motorBatteryLevel ?? parameters.moduleBatteryLevel
            self.lock = parameters.lock
            self.alarm = parameters.alarm
            self.lighting = parameters.lighting
            self.moduleState = parameters.moduleState
            self.motorAssistance = parameters.motorAssistance
            self.speed = parameters.speed
            self.mutedSounds = parameters.mutedSounds
            self.errorCode = parameters.errorCode
            self.distance = parameters.distance
            self.region = parameters.region
            self.unit = parameters.unit
            self.batteryState = parameters.batteryState
        }
          if let moduleBatteryLevel = try await self.readRequest(self.profile.createBatteryLevelReadRequest()) {
             print("Module battery level: \(moduleBatteryLevel)%")
            self.batteryLevel = moduleBatteryLevel
        }
        if let lock = try await self.readRequest(self.profile.createLockReadRequest()) {
            print("Lock: \(lock)")
            self.lock = lock
        }
        if let alarm = try await self.readRequest(self.profile.createAlarmReadRequest()) {
            print("Alarm: \(alarm)")
            self.alarm = alarm
        }
        if let lighting = try await self.readRequest(self.profile.createLightingReadRequest()) {
            print("Lighting: \(lighting)")
            self.lighting = lighting
        }
        if let moduleState = try await self.readRequest(self.profile.createModuleStateReadRequest()) {
            print("Module state: \(moduleState)")
            self.moduleState = moduleState
        }
        if let speed = try await self.readRequest(self.profile.createSpeedReadRequest()) {
            print("Speed: \(speed)")
            self.speed = speed
        }
        if let mutedSounds = try await self.readRequest(self.profile.createMuteSoundReadRequest()) {
            print("Muted sounds: \(mutedSounds.description)")
            self.mutedSounds = mutedSounds
        }
        if let errorCode = try await self.readRequest(self.profile.createErrorCodeReadRequest()) {
            print("ErrorCode: \(errorCode)")
            self.errorCode = errorCode
        }
        if let distance = try await self.readRequest(self.profile.createDistanceReadRequest()) {
            print("Distance: \(distance) km")
            self.distance = distance
        }
        if let batteryState = try await self.readRequest(self.profile.createBatteryStateReadRequest()) {
            print("BatteryState: \(batteryState)")
            self.batteryState = batteryState
        }

        try self.notifyRequest(profile.createParametersReadRequest()) { parameters in
            print("Notification: parameters:\n\(parameters.description)")
            self.batteryLevel = parameters.motorBatteryLevel ?? parameters.moduleBatteryLevel
            self.lock = parameters.lock
            self.alarm = parameters.alarm
            self.lighting = parameters.lighting
            self.moduleState = parameters.moduleState
            self.motorAssistance = parameters.motorAssistance
            self.speed = parameters.speed
            self.mutedSounds = parameters.mutedSounds
            self.errorCode = parameters.errorCode
            self.distance = parameters.distance
            self.region = parameters.region
            self.unit = parameters.unit
            self.batteryState = parameters.batteryState
        }
        try? self.notifyRequest(profile.createBatteryLevelReadRequest()) { value in
            self.batteryLevel = value
            print("Notification: battery level: \(self.batteryLevel)")
        }
        try self.notifyRequest(profile.createBatteryStateReadRequest()) { value in
            self.batteryState = value
            print("Notification: battery charging: \("\(self.batteryState)")")
        }
        try self.notifyRequest(profile.createLockReadRequest()) { value in
            self.lock = value
            print("Notification: lock: \("\(self.lock)")")
        }
        try self.notifyRequest(profile.createAlarmReadRequest()) { value in
            self.alarm = value
            print("Notification: alarm: \("\(self.alarm ?? .off)")")
        }
        try self.notifyRequest(profile.createLightingReadRequest()) { value in
            self.lighting = value
            print("Notification: lighting: \("\(self.lighting)")")
        }
        try self.notifyRequest(profile.createModuleStateReadRequest()) { value in
            self.moduleState = value
            print("Notification: module state: \("\(self.moduleState)")")
        }
        try self.notifyRequest(profile.createErrorCodeReadRequest()) { value in
            self.errorCode = value
            print("Notification: error code: \(self.errorCode)")
        }
        try self.notifyRequest(profile.createSpeedReadRequest()) { value in
            self.speed = value
            print("Notification: speed: \(self.speed)")
            if self.configuration.motionUnlock && self.lock == .locked {
                Task {
                    print("Unlocking because of motion...")
                    try await self.setLocked(.unlocked)
                }
            }
        }
        try self.notifyRequest(profile.createDistanceReadRequest()) { value in
            self.distance = value
            print("Notification: distance: \(self.distance)")
        }
        try self.notifyRequest(profile.createMuteSoundReadRequest()) { value in
            self.mutedSounds = value
            print("Notification: muted sounds: \(self.mutedSounds)")
        }
    }

       public func wakeup () async throws {
        if self.moduleState == .standby {
            print("Waking the bike up!")
            try await self.writeRequest(self.profile.createModuleStateWriteRequest(value: .on))
            try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
        }
    }

    public func setLocked (_ value: Lock) async throws {
        print("Setting lock to \("\(value)")")
        try await self.writeRequest(self.profile.createLockWriteRequest(value: value))
    }

    public func setLighting (_ value: Lighting) async throws {
        print("Setting lighting to \("\(value)")")
        try await self.writeRequest(self.profile.createLightingWriteRequest(value: value))
    }

    public func setAlarm (_ value: Alarm) async throws {
        print("Setting alarm to \("\(value)")")
        try await self.writeRequest(self.profile.createAlarmWriteRequest(value: value))
    }

    public func setMotorAssistance (_ value: MotorAssistance) async throws {
        print("Setting motor assistance to \("\(value)")")
        if let region = self.region {
            try await self.writeRequest(self.profile.createMotorAssistanceWriteRequest(value: value, region: region))
        }
    }

    public func setRegion (_ value: Region) async throws {
        print("Setting region to \("\(value)")")
        if let motorAssistance = self.motorAssistance {
            try await self.writeRequest(self.profile.createMotorAssistanceWriteRequest(value: motorAssistance, region: value))
        }
    }

    public func setUnit (_ value: Unit) async throws {
        print("Setting unit to \("\(value)")")
        try await self.writeRequest(self.profile.createUnitWriteRequest(value: value))
    }

    public func setMuteState(_ value: MutedSounds) async throws {
        print("Setting muted sounds to \(value.description)")
        try await self.writeRequest(self.profile.createMutedSoundsWriteRequest(value: value))
    }

    public func playSound (_ sound: Sound, repeat count: UInt8 = 1) async throws {
        print("Playing sound \("\(sound)") \(count) times.")
        try await self.writeRequest(self.profile.createPlaySoundWriteRequest(sound: sound, repeats: count))
    }

    public func setBackupCode (_ code: Int) async throws {
        if code < 111 || code > 999 {
            throw BikeConnectionError.codeOutOfRange
        }
        print("Setting backup code to \(code).")
        try await self.writeRequest(self.profile.createBackupCodeWriteRequest(code: code))
    }

    public func connect () {
        if self.connection != nil {
            return
        }

        self.connection = BluetoothConnection(identifier: self.identifier, reconnectInterval: 1)
        self.bluetoothEvents = self.connection?.events.sink { event in
            switch event {
            case .connected:
                Task {
                    do {
                        try await self.setupConnection()
                        self.events.send(.connected)
                    } catch {
                        self.events.send(.error(error))
                    }
                }

            case .disconnected:
                self.events.send(.disconnected)

            case .error(let error):
                self.events.send(.error(error))
            }
        }

        connection?.connect()
    }

    public func disconnect () {
        self.connection?.disconnectPeripheral()
        self.connection = nil
        self.bluetoothEvents?.cancel()
        self.bluetoothEvents = nil
    }
}
