//
//  BikeConnection.swift
//  VanMoofTest
//
//  Created by Sebastian Boettcher on 09.08.23.
//

import CoreBluetooth

public protocol BikeConnectionDelegate: AnyObject {
    func bikeConnectionDidConnect(_ connection: BikeConnection)
    func bikeConnectionDidDisconnect(_ connection: BikeConnection)
    func bikeConnection(_ connection: BikeConnection, failed error: Error)
    func bikeConnection(_ connection: BikeConnection, didChangeLocked locked: Lock)
    func bikeConnection(_ connection: BikeConnection, didChangeLighting lighting: Lighting)
    func bikeConnection(_ connection: BikeConnection, didChangeAlarm alarm: Alarm)
    func bikeConnection(_ connection: BikeConnection, didChangeBatteryLevel level: Int)
    func bikeConnection(_ connection: BikeConnection, didChangeBatteryState state: BatteryState)
    func bikeConnection(_ connection: BikeConnection, didChangeMotorAssistance motorAssistance: MotorAssistance)
    func bikeConnection(_ connection: BikeConnection, didChangeMutedSounds mutedSounds: MutedSounds)
    func bikeConnection(_ connection: BikeConnection, didChangeSpeed speed: Int)
    func bikeConnection(_ connection: BikeConnection, didChangeDistance distance: Double)
    func bikeConnection(_ connection: BikeConnection, didChangeRegion region: Region)
    func bikeConnection(_ connection: BikeConnection, didChangeUnit unit: Unit)
    func bikeConnection(_ connection: BikeConnection, didChangeModuleState state: ModuleState)
}

public class BikeConnection: NSObject {

    public let bike: Bike

    public var proximityUnlock: Bool
    public var motionUnlock: Bool

    public var isConnected: Bool { return self.connection?.isConnected ?? false }

    private (set) public var lock: Lock = .locked {
        didSet {
            self.delegate?.bikeConnection(self, didChangeLocked: self.lock)
        }
    }

    private (set) public var alarm: Alarm? {
        didSet {
            if let alarm = self.alarm {
                self.delegate?.bikeConnection(self, didChangeAlarm: alarm)
            }
        }
    }

    private (set) public var lighting: Lighting = .off {
        didSet {
            self.delegate?.bikeConnection(self, didChangeLighting: self.lighting)
        }
    }

    private (set) public var batteryLevel: Int = 0 {
        didSet {
            self.delegate?.bikeConnection(self, didChangeBatteryLevel: self.batteryLevel)
        }
    }

    private (set) public var batteryState: BatteryState = .discharging {
        didSet {
            self.delegate?.bikeConnection(self, didChangeBatteryState: self.batteryState)
        }
    }

    private (set) public var moduleState: ModuleState = .off {
        didSet {
            self.delegate?.bikeConnection(self, didChangeModuleState: self.moduleState)
        }
    }

    private (set) public var errorCode: ErrorCode = ErrorCode()

    private (set) public var motorAssistance: MotorAssistance? {
        didSet {
            if let motorAssistance = self.motorAssistance {
                self.delegate?.bikeConnection(self, didChangeMotorAssistance: motorAssistance)
            }
        }
    }

    private (set) public var mutedSounds: MutedSounds = [] {
        didSet {
            self.delegate?.bikeConnection(self, didChangeMutedSounds: self.mutedSounds)
        }
    }

    private (set) public var speed: Int = 0 {
        didSet {
            self.delegate?.bikeConnection(self, didChangeSpeed: self.speed)
        }
    }

    private (set) public var distance: Double = 0 {
        didSet {
            self.delegate?.bikeConnection(self, didChangeDistance: self.distance)
        }
    }

    private (set) public var region: Region? {
        didSet {
           if let region = self.region {
                self.delegate?.bikeConnection(self, didChangeRegion: region)
           }
        }
    }

    private (set) public var unit: Unit? {
        didSet {
            if let unit = self.unit {
                self.delegate?.bikeConnection(self, didChangeUnit: unit)
            }
        }
    }

    private (set) public var parameters: Parameters? {
        didSet {
            if let parameters = self.parameters {
                DispatchQueue.main.async {
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
            }
        }
    }

    private var connection: BluetoothConnection?

    public weak var delegate: BikeConnectionDelegate?

    public init (bike: Bike, proximityUnlock: Bool, motionUnlock: Bool) throws {
        self.bike = bike
        self.proximityUnlock = proximityUnlock
        self.motionUnlock = motionUnlock
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
            data = try data?.decrypt_aes_ecb_zero(key: self.bike.key)
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
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }

        let challenge = try await self.readRequest(profile.createChallengeReadRequest())
        guard var data = challenge?[...1] else {
            return
        }

        if let command = request.command {
            data += Data([command])
        }

        data += request.data

        let payload = try data.encrypt_aes_ecb_zero(key: self.bike.key)
        try await connection.writeValue(payload, for: request.uuid)
    }

    private func notifyRequest<T> (_ request: ReadRequest<T>?, callback: @escaping ((T?) -> Void)) throws {
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
                    data = try data?.decrypt_aes_ecb_zero(key: self.bike.key)
                }
                callback(request.parse(data))
            } catch {
                self.delegate?.bikeConnection(self, failed: error)
            }
        }
    }

    private func readParameters () async throws -> Parameters {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        if let parameters = try await self.readRequest(profile.createParametersReadRequest()) {
            return parameters
        } else {
            let moduleState = try await self.readRequest(profile.createModuleStateReadRequest()) ?? .off
            return Parameters(data: nil,
                              alarm: try await self.readRequest(profile.createAlarmReadRequest()) ?? .off,
                              moduleState: moduleState,
                              lock: try await self.readRequest(profile.createLockReadRequest()) ?? .locked,
                              batteryState: try await self.readRequest(profile.createBatteryStateReadRequest()) ?? .discharging,
                              speed: try await self.readRequest(profile.createSpeedReadRequest()) ?? 0,
                              motorBatteryLevel: nil,
                              moduleBatteryLevel: try await self.readRequest(profile.createBatteryLevelReadRequest()) ?? 0,
                              lighting: try await self.readRequest(profile.createLightingReadRequest()) ?? .off,
                              unit: nil,
                              motorAssistance: nil,
                              region: nil,
                              mutedSounds: try await self.readRequest(profile.createMuteSoundReadRequest()) ?? .none,
                              distance: try await self.readRequest(profile.createDistanceReadRequest()) ?? 0.0,
                              errorCode: try await self.readRequest(profile.createErrorCodeReadRequest()) ?? ErrorCode())
        }
    }

    private func authenticate () async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Authenticating...")
        try await self.writeRequest(profile.createAuthenticationWriteRequest(key: self.bike.key))
    }

    public func wakeup () async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        if self.moduleState == .standby {
            print("Waking the bike up!")
            try await self.writeRequest(profile.createModuleStateWriteRequest(value: .on))
            try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
        }
    }

    public func setLocked (_ value: Lock) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Setting lock to \("\(value)")")
        try await self.writeRequest(profile.createLockWriteRequest(value: value))
    }

    public func setLighting (_ value: Lighting) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Setting lighting to \("\(value)")")
        try await self.writeRequest(profile.createLightingWriteRequest(value: value))
    }

    public func setAlarm (_ value: Alarm) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Setting alarm to \("\(value)")")
        try await self.writeRequest(profile.createAlarmWriteRequest(value: value))
    }

    public func setMotorAssistance (_ value: MotorAssistance) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Setting motor assistance to \("\(value)")")
        if let region = self.region {
            try await self.writeRequest(profile.createMotorAssistanceWriteRequest(value: value, region: region))
        }
    }

    public func setRegion (_ value: Region) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Setting region to \("\(value)")")
        if let motorAssistance = self.motorAssistance {
            try await self.writeRequest(profile.createMotorAssistanceWriteRequest(value: motorAssistance, region: value))
        }
    }

    public func setUnit (_ value: Unit) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Setting unit to \("\(value)")")
        try await self.writeRequest(profile.createUnitWriteRequest(value: value))
    }

    public func setMuteState(_ value: MutedSounds) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Setting muted sounds to \(value.description)")
        try await self.writeRequest(profile.createMutedSoundsWriteRequest(value: value))
    }

    public func playSound (_ sound: Sound, repeat count: UInt8 = 1) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        print("Playing sound \("\(sound)") \(count) times.")
        try await self.writeRequest(profile.createPlaySoundWriteRequest(sound: sound, repeats: count))
    }

    public func setBackupCode (_ code: Int) async throws {
        guard let profile = self.bike.profile else {
            throw BikeConnectionError.bikeNotSupported
        }
        if code < 111 || code > 999 {
            throw BikeConnectionError.codeOutOfRange
        }
        print("Setting backup code to \(code).")
        try await self.writeRequest(profile.createBackupCodeWriteRequest(code: code))
    }

    public func connect () {
        self.connection = BluetoothConnection(delegate: self, identifier: self.bike.identifier, reconnectInterval: 1)
    }

    public func disconnect () {
        self.connection?.disconnectPeripheral()
        self.connection?.delegate = nil
        self.connection = nil
    }
}

extension BikeConnection: BluetoothConnectionDelegate {
    internal func bluetoothConnection (_ connection: BluetoothConnection, failed error: Error) {
        print("Connection failed with error \(error)")
        self.delegate?.bikeConnection(self, failed: error)
    }

    internal func bluetoothDidConnect (_ connection: BluetoothConnection) {
        Task {
            do {
                guard let profile = self.bike.profile else {
                    throw BikeConnectionError.bikeNotSupported
                }

                print("Connected")

                try await self.authenticate()

                if self.proximityUnlock {
                    print("Unlocking because of proximity...")
                    try await self.setLocked(.unlocked)
                }

                print("Reading parameters...")
                self.parameters = try await self.readParameters()
                print("Parameters:\n\(self.parameters?.description ?? "-")")

                try self.notifyRequest(profile.createParametersReadRequest()) { parameters in
                    self.parameters = parameters
                    print("Notification: parameters:\n\(self.parameters?.description ?? "-")")
                }
                try? self.notifyRequest(profile.createBatteryLevelReadRequest()) { value in
                    self.batteryLevel = value ?? 0
                    print("Notification: battery level: \(self.batteryLevel)")
                }
                try self.notifyRequest(profile.createBatteryStateReadRequest()) { value in
                    self.batteryState = value ?? .discharging
                    print("Notification: battery charging: \("\(self.batteryState)")")
                }
                try self.notifyRequest(profile.createLockReadRequest()) { value in
                    self.lock = value ?? .locked
                    print("Notification: lock: \("\(self.lock)")")
                }
                try self.notifyRequest(profile.createAlarmReadRequest()) { value in
                    self.alarm = value
                    print("Notification: alarm: \("\(self.alarm ?? .off)")")
                }
                try self.notifyRequest(profile.createLightingReadRequest()) { value in
                    self.lighting = value ?? .off
                    print("Notification: lighting: \("\(self.lighting)")")
                }
                try self.notifyRequest(profile.createModuleStateReadRequest()) { value in
                    self.moduleState = value ?? .off
                    print("Notification: module state: \("\(self.moduleState)")")
                }
                try self.notifyRequest(profile.createErrorCodeReadRequest()) { value in
                    self.errorCode = value ?? ErrorCode()
                    print("Notification: error code: \(self.errorCode)")
                }
                try self.notifyRequest(profile.createSpeedReadRequest()) { value in
                    self.speed = value ?? 0
                    print("Notification: speed: \(self.speed)")
                    if self.motionUnlock && self.lock == .locked {
                        Task {
                            print("Unlocking because of motion...")
                            try await self.setLocked(.unlocked)
                        }
                    }
                }
                try self.notifyRequest(profile.createDistanceReadRequest()) { value in
                    self.distance = value ?? 0.0
                    print("Notification: distance: \(self.distance)")
                }
                try self.notifyRequest(profile.createMuteSoundReadRequest()) { value in
                    self.mutedSounds = value ?? .none
                    print("Notification: muted sounds: \(self.mutedSounds)")
                }

                DispatchQueue.main.async {
                    self.delegate?.bikeConnectionDidConnect(self)
                }
            } catch {
                print("Connection failed with error: \(error)")
                DispatchQueue.main.async {
                    self.delegate?.bikeConnection(self, failed: error)
                }
            }
        }
    }

    internal func bluetoothDidDisconnect (_ connection: BluetoothConnection) {
        self.delegate?.bikeConnectionDidDisconnect(self)
        print("Disconnected")
    }
}
