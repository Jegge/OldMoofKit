//
//  BikeConnection.swift
//  VanMoofTest
//
//  Created by Sebastian Boettcher on 09.08.23.
//

import CoreBluetooth
import Combine

public final class Bike: Codable {
    enum CodingKeys: String, CodingKey {
        case identifier
        case details
    }

    public let identifier: UUID
    public let details: BikeDetails

    public let connectionStatePublisher = PassthroughSubject<BikeState, Never>()
    public let errorPublisher = PassthroughSubject<Error, Never>()
    public let lockPublisher = PassthroughSubject<Lock, Never>()
    public let alarmPublisher = PassthroughSubject<Alarm, Never>()
    public let lightingPublisher = PassthroughSubject<Lighting, Never>()
    public let batteryLevelPublisher = PassthroughSubject<Int, Never>()
    public let batteryStatePublisher = PassthroughSubject<BatteryState, Never>()
    public let moduleStatePublisher = PassthroughSubject<ModuleState, Never>()
    public let errorCodePublisher = PassthroughSubject<ErrorCode, Never>()
    public let motorAssistancePublisher = PassthroughSubject<MotorAssistance, Never>()
    public let mutedSoundsPublisher = PassthroughSubject<MutedSounds, Never>()
    public let speedPublisher = PassthroughSubject<Int, Never>()
    public let distancePublisher = PassthroughSubject<Double, Never>()
    public let regionPublisher = PassthroughSubject<Region, Never>()
    public let unitPublisher = PassthroughSubject<Unit, Never>()

    private var key: Data
    private var profile: Profile
    private var connection: BluetoothConnection?
    private var state: AnyCancellable?
    private var errors: AnyCancellable?
    private var notifications: AnyCancellable?
    private var notificationCallbacks: [CBUUID: ((Data?) -> Void)] = [:]

    public var isConnected: Bool {
        return self.connection?.isConnected ?? false
    }

    public var signalStrength: Int {
        get async {
            return (try? await self.connection?.readRssi()) ?? -1
        }
    }

    private (set) public var lock: Lock = .locked {
        didSet {
            self.lockPublisher.send(self.lock)
        }
    }
    private (set) public var alarm: Alarm? {
        didSet {
            if let alarm = self.alarm {
                self.alarmPublisher.send(alarm)
            }
        }
    }
    private (set) public var lighting: Lighting = .off {
        didSet {
            self.lightingPublisher.send(self.lighting)
        }
    }
    private (set) public var batteryLevel: Int = 0 {
        didSet {
            self.batteryLevelPublisher.send(self.batteryLevel)
        }
    }
    private (set) public var batteryState: BatteryState = .discharging {
        didSet {
            self.batteryStatePublisher.send(self.batteryState)
        }
    }
    private (set) public var moduleState: ModuleState = .off {
        didSet {
            self.moduleStatePublisher.send(self.moduleState)
        }
    }
    private (set) public var errorCode: ErrorCode = ErrorCode() {
        didSet {
            self.errorCodePublisher.send(self.errorCode)
        }
    }
    private (set) public var motorAssistance: MotorAssistance? {
        didSet {
            if let motorAssistance = self.motorAssistance {
                self.motorAssistancePublisher.send(motorAssistance)
            }
        }
    }
    private (set) public var mutedSounds: MutedSounds = [] {
        didSet {
            self.mutedSoundsPublisher.send(self.mutedSounds)
        }
    }
    private (set) public var speed: Int = 0 {
        didSet {
            self.speedPublisher.send(self.speed)
        }
    }
    private (set) public var distance: Double = 0 {
        didSet {
            self.distancePublisher.send(self.distance)
        }
    }
    private (set) public var region: Region? {
        didSet {
            if let region = self.region {
                self.regionPublisher.send(region)
            }
        }
    }
    private (set) public var unit: Unit? {
        didSet {
            if let unit = self.unit {
                self.unitPublisher.send(unit)
            }
        }
    }

    private init (identifier: UUID, details: BikeDetails, profile: Profile) {
        self.identifier = identifier
        self.details = details
        self.profile = profile
        self.key = Data(hexString: details.encryptionKey) ?? Data()
    }

    public convenience init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(UUID.self, forKey: .identifier)
        let details = try container.decode(BikeDetails.self, forKey: .details)
        guard let profile = details.profile else {
            throw BikeError.bikeNotSupported
        }
        self.init(identifier: identifier, details: details, profile: profile)
    }

    public convenience init (scanningForBikeMatchingDetails details: BikeDetails, timeout seconds: TimeInterval = 30) async throws {
        guard let profile = details.profile else {
            throw BikeError.bikeNotSupported
        }
        let scanner = BluetoothScanner()
        let identifier = try await scanner.scanForPeripherals(withServices: [profile.identifier], name: details.deviceName, timeout: seconds)
        self.init(identifier: identifier, details: details, profile: profile)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.details, forKey: .details)
    }

      private func readRequest<T> (_ request: ReadRequest<T>?) async throws -> T? {
        guard let request = request else {
            return nil
        }
        guard let connection = self.connection else {
            throw BikeError.notConnected
        }

        var data = try await connection.readValue(for: request.uuid)
        if request.decrypt {
            data = try data?.decrypt_aes_ecb_zero(key: self.key)
        }

        return request.parse(data)
    }

    private func writeRequest (_ request: WriteRequest?) async throws {
        guard let request = request else {
            return
        }
        guard let connection = self.connection else {
            throw BikeError.notConnected
        }

        let challenge = try await self.readRequest(self.profile.createChallengeReadRequest())
        guard var data = challenge?[...1] else {
            return
        }

        if let command = request.command {
            data += Data([command])
        }

        data += request.data

        let payload = try data.encrypt_aes_ecb_zero(key: self.key)
        try await connection.writeValue(payload, for: request.uuid)
    }

    private func notifyRequest<T> (_ request: ReadRequest<T>?, callback: @escaping ((T) -> Void)) throws {
        guard let request = request else {
            return
        }
        guard let connection = self.connection else {
            throw BikeError.notConnected
        }

        self.notificationCallbacks[request.uuid] = { data in
            var data = data
            do {
                if request.decrypt {
                    data = try data?.decrypt_aes_ecb_zero(key: self.key)
                }
                if let payload = request.parse(data) {
                    callback(payload)
                }
            } catch {
                self.errorPublisher.send(error)
            }
        }

        connection.setNotifyValue(enabled: true, for: request.uuid)
    }

    private func setupConnection () async throws {
        print("Authenticating...")
        try await self.writeRequest(self.profile.createAuthenticationWriteRequest(key: self.key))

        print("Reading parameters...")
        if let parameters = try await self.readRequest(self.profile.createParametersReadRequest()) {
            print("Parameters:\n\(parameters.description)")
            self.batteryLevel = parameters.motorBatteryLevel ?? parameters.moduleBatteryLevel
            self.lock = parameters.lock
            self.alarm = parameters.alarm
            self.lighting = parameters.lighting
            self.moduleState = parameters.moduleState
            self.motorAssistance = parameters.motorAssistance
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
            print("Notification: battery level: \(value)%")
            self.batteryLevel = value
        }
        try self.notifyRequest(profile.createBatteryStateReadRequest()) { value in
            print("Notification: battery charging: \(value)")
            self.batteryState = value
        }
        try self.notifyRequest(profile.createLockReadRequest()) { value in
            print("Notification: lock: \(value)")
            self.lock = value
        }
        try self.notifyRequest(profile.createAlarmReadRequest()) { value in
            print("Notification: alarm: \(value)")
            self.alarm = value
        }
        try self.notifyRequest(profile.createLightingReadRequest()) { value in
            print("Notification: lighting: \(value)")
            self.lighting = value
        }
        try self.notifyRequest(profile.createModuleStateReadRequest()) { value in
            print("Notification: module state: \(value)")
            self.moduleState = value
        }
        try self.notifyRequest(profile.createErrorCodeReadRequest()) { value in
            print("Notification: error code: \(value)")
            self.errorCode = value
        }
        try self.notifyRequest(profile.createSpeedReadRequest()) { value in
            print("Notification: speed: \(value)")
            self.speed = value
        }
        try self.notifyRequest(profile.createDistanceReadRequest()) { value in
            print("Notification: distance: \(value) km")
            self.distance = value
        }
        try self.notifyRequest(profile.createMuteSoundReadRequest()) { value in
            print("Notification: muted sounds: \(value)")
            self.mutedSounds = value
        }
    }

    public func wakeup () async throws {
        if self.moduleState == .standby {
            print("Waking the bike up!")
            try await self.writeRequest(self.profile.createModuleStateWriteRequest(value: .on))
            try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
        }
    }

    public func set (lock value: Lock) async throws {
        print("Setting lock to \(value)")
        try await self.writeRequest(self.profile.createLockWriteRequest(value: value))
    }

    public func set (lighting value: Lighting) async throws {
        print("Setting lighting to \(value)")
        try await self.writeRequest(self.profile.createLightingWriteRequest(value: value))
    }

    public func set (alarm value: Alarm) async throws {
        print("Setting alarm to \(value)")
        try await self.writeRequest(self.profile.createAlarmWriteRequest(value: value))
    }

    public func set (motorAssistance value: MotorAssistance) async throws {
        print("Setting motor assistance to \(value)")
        if let region = self.region {
            try await self.writeRequest(self.profile.createMotorAssistanceWriteRequest(value: value, region: region))
        }
    }

    public func set (region value: Region) async throws {
        print("Setting region to \(value)")
        if let motorAssistance = self.motorAssistance {
            try await self.writeRequest(self.profile.createMotorAssistanceWriteRequest(value: motorAssistance, region: value))
        }
    }

    public func set (unit value: Unit) async throws {
        print("Setting unit to \(value)")
        try await self.writeRequest(self.profile.createUnitWriteRequest(value: value))
    }

    public func set(mutedSounds value: MutedSounds) async throws {
        print("Setting muted sounds to \(value.description)")
        try await self.writeRequest(self.profile.createMutedSoundsWriteRequest(value: value))
    }

    public func playSound (_ sound: Sound, repeat count: UInt8 = 1) async throws {
        print("Playing sound \(sound) \(count) times.")
        try await self.writeRequest(self.profile.createPlaySoundWriteRequest(sound: sound, repeats: count))
    }

    public func set (backupCode code: Int) async throws {
        if code < 111 || code > 999 {
            throw BikeError.codeOutOfRange
        }
        print("Setting backup code to \(code).")
        try await self.writeRequest(self.profile.createBackupCodeWriteRequest(code: code))
    }

    public func connect () async throws {
        if self.connection != nil {
            return
        }

        self.connection = BluetoothConnection(identifier: self.identifier, reconnectInterval: 1)

        self.state = self.connection?.state.sink { state in
            switch state {
            case .connected:
                Task {
                    do {
                        try await self.setupConnection()
                        self.connectionStatePublisher.send(.connected)
                    } catch {
                        self.errorPublisher.send(error)
                    }
                }

            case .disconnected:
                self.notificationCallbacks = [:]
                self.connectionStatePublisher.send(.disconnected)
            }
        }

        self.errors = self.connection?.errors.sink { error in
            self.errorPublisher.send(error)
        }

        self.notifications = self.connection?.notifications.sink { notification in
            self.notificationCallbacks[notification.uuid]?(notification.data)
        }

        try await connection?.connect()
    }

    public func disconnect () {
        self.connection?.disconnectPeripheral()
        self.connection = nil
        self.state?.cancel()
        self.errors?.cancel()
        self.notifications?.cancel()
        self.state = nil
        self.errors = nil
        self.notifications = nil
    }
}
