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

    let identifier: UUID
    let key: Data
    let profile: Profile

    var proximityUnlock: Bool
    var motionUnlock: Bool

    var isConnected: Bool { return self.connection?.isConnected ?? false }

    private (set) var lock: Lock = .locked {
        didSet {
            self.delegate?.bikeConnection(self, didChangeLocked: self.lock)
        }
    }

    private (set) var alarm: Alarm? {
        didSet {
            if let alarm = self.alarm {
                self.delegate?.bikeConnection(self, didChangeAlarm: alarm)
            }
        }
    }

    private (set) var lighting: Lighting = .off {
        didSet {
            self.delegate?.bikeConnection(self, didChangeLighting: self.lighting)
        }
    }

    private (set) var batteryLevel: Int = 0 {
        didSet {
            self.delegate?.bikeConnection(self, didChangeBatteryLevel: self.batteryLevel)
        }
    }

    private (set) var batteryState: BatteryState = .discharging {
        didSet {
            self.delegate?.bikeConnection(self, didChangeBatteryState: self.batteryState)
        }
    }

    private (set) var moduleState: ModuleState = .off {
        didSet {
            self.delegate?.bikeConnection(self, didChangeModuleState: self.moduleState)
        }
    }

    private (set) var errorCode: ErrorCode = ErrorCode()

    private (set) var motorAssistance: MotorAssistance? {
        didSet {
            if let motorAssistance = self.motorAssistance {
                self.delegate?.bikeConnection(self, didChangeMotorAssistance: motorAssistance)
            }
        }
    }

    private (set) var mutedSounds: MutedSounds = [] {
        didSet {
            self.delegate?.bikeConnection(self, didChangeMutedSounds: self.mutedSounds)
        }
    }

    private (set) var speed: Int = 0 {
        didSet {
            self.delegate?.bikeConnection(self, didChangeSpeed: self.speed)
        }
    }

    private (set) var distance: Double = 0 {
        didSet {
            self.delegate?.bikeConnection(self, didChangeDistance: self.distance)
        }
    }

    private (set) var region: Region? {
        didSet {
           if let region = self.region {
                self.delegate?.bikeConnection(self, didChangeRegion: region)
           }
        }
    }

    private (set) var unit: Unit? {
        didSet {
            if let unit = self.unit {
                self.delegate?.bikeConnection(self, didChangeUnit: unit)
            }
        }
    }

    private (set) var parameters: Parameters? {
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

    weak var delegate: BikeConnectionDelegate?

    public init (identifier: UUID, key: Data, profile name: String, proximityUnlock: Bool, motionUnlock: Bool) throws {
        guard let profile = Profiles.profile(named: name) else {
            throw BikeConnectionError.bikeNotSupported
        }
        self.identifier = identifier
        self.key = key
        self.profile = profile
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
            data = try data?.decrypt_aes_ecb_zero(key: self.key)
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

        let payload = try data.encrypt_aes_ecb_zero(key: self.key)
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
                    data = try data?.decrypt_aes_ecb_zero(key: self.key)
                }
                callback(request.parse(data))
            } catch {
                self.delegate?.bikeConnection(self, failed: error)
            }
        }
    }

    private func readParameters () async throws -> Parameters {
        if let parameters = try await self.readRequest(self.profile.createParametersReadRequest()) {
            return parameters
        } else {
            let moduleState = try await self.readRequest(self.profile.createModuleStateReadRequest()) ?? .off
            return Parameters(data: nil,
                              alarm: try await self.readRequest(self.profile.createAlarmReadRequest()) ?? .off,
                              moduleState: moduleState,
                              lock: try await self.readRequest(self.profile.createLockReadRequest()) ?? .locked,
                              batteryState: try await self.readRequest(self.profile.createBatteryStateReadRequest()) ?? .discharging,
                              speed: try await self.readRequest(self.profile.createSpeedReadRequest()) ?? 0,
                              motorBatteryLevel: nil,
                              moduleBatteryLevel: try await self.readRequest(self.profile.createBatteryLevelReadRequest()) ?? 0,
                              lighting: try await self.readRequest(self.profile.createLightingReadRequest()) ?? .off,
                              unit: nil,
                              motorAssistance: nil,
                              region: nil,
                              mutedSounds: try await self.readRequest(self.profile.createMuteSoundReadRequest()) ?? .none,
                              distance: try await self.readRequest(self.profile.createDistanceReadRequest()) ?? 0.0,
                              errorCode: try await self.readRequest(self.profile.createErrorCodeReadRequest()) ?? ErrorCode())
        }
    }

    private func authenticate () async throws {
        print("Authenticating...")
        try await self.writeRequest(self.profile.createAuthenticationWriteRequest(key: self.key))
    }

    func wakeup () async throws {
        if self.moduleState == .standby {
            print("Waking the bike up!")
            try await self.writeRequest(self.profile.createModuleStateWriteRequest(value: .on))
            try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
        }
    }

    func setLocked (_ value: Lock) async throws {
        print("Setting lock to \("\(value)")")
        try await self.writeRequest(self.profile.createLockWriteRequest(value: value))
    }

    func setLighting (_ value: Lighting) async throws {
        print("Setting lighting to \("\(value)")")
        try await self.writeRequest(self.profile.createLightingWriteRequest(value: value))
    }

    func setAlarm (_ value: Alarm) async throws {
        print("Setting alarm to \("\(value)")")
        try await self.writeRequest(self.profile.createAlarmWriteRequest(value: value))
    }

    func setMotorAssistance (_ value: MotorAssistance) async throws {
        print("Setting motor assistance to \("\(value)")")
        if let region = self.region {
            try await self.writeRequest(self.profile.createMotorAssistanceWriteRequest(value: value, region: region))
        }
    }

    func setRegion (_ value: Region) async throws {
        print("Setting region to \("\(value)")")
        if let motorAssistance = self.motorAssistance {
            try await self.writeRequest(self.profile.createMotorAssistanceWriteRequest(value: motorAssistance, region: value))
        }
    }

    func setUnit (_ value: Unit) async throws {
        print("Setting unit to \("\(value)")")
        try await self.writeRequest(self.profile.createUnitWriteRequest(value: value))
    }

    func setMuteState(_ value: MutedSounds) async throws {
        print("Setting muted sounds to \(value.description)")
        try await self.writeRequest(self.profile.createMutedSoundsWriteRequest(value: value))
    }

    func playSound (_ sound: Sound, repeat count: UInt8 = 1) async throws {
        print("Playing sound \("\(sound)") \(count) times.")
        try await self.writeRequest(self.profile.createPlaySoundWriteRequest(sound: sound, repeats: count))
    }

    func setBackupCode (_ code: Int) async throws {
        if code < 111 || code > 999 {
            throw BikeConnectionError.codeOutOfRange
        }
        print("Setting backup code to \(code).")
        try await self.writeRequest(self.profile.createBackupCodeWriteRequest(code: code))
    }

    func connect () {
        self.connection = BluetoothConnection(delegate: self, identifier: self.identifier, reconnectInterval: 1)
    }

    func disconnect () {
        self.connection?.disconnectPeripheral()
        self.connection?.delegate = nil
        self.connection = nil
    }
}

extension BikeConnection: BluetoothConnectionDelegate {
    func bluetoothConnection (_ connection: BluetoothConnection, failed error: Error) {
        print("Connection failed with error \(error)")
        self.delegate?.bikeConnection(self, failed: error)
    }

    func bluetoothDidConnect (_ connection: BluetoothConnection) {
        Task {
            do {
                print("Connected")

                try await self.authenticate()

                if self.proximityUnlock {
                    print("Unlocking because of proximity...")
                    try await self.setLocked(.unlocked)
                }

                print("Reading parameters...")
                self.parameters = try await self.readParameters()
                print("Parameters:\n\(self.parameters?.description ?? "-")")

                try self.notifyRequest(self.profile.createParametersReadRequest()) { parameters in
                    self.parameters = parameters
                    print("Notification: parameters:\n\(self.parameters?.description ?? "-")")
                }
                try? self.notifyRequest(self.profile.createBatteryLevelReadRequest()) { value in
                    self.batteryLevel = value ?? 0
                    print("Notification: battery level: \(self.batteryLevel)")
                }
                try self.notifyRequest(self.profile.createBatteryStateReadRequest()) { value in
                    self.batteryState = value ?? .discharging
                    print("Notification: battery charging: \("\(self.batteryState)")")
                }
                try self.notifyRequest(self.profile.createLockReadRequest()) { value in
                    self.lock = value ?? .locked
                    print("Notification: lock: \("\(self.lock)")")
                }
                try self.notifyRequest(self.profile.createAlarmReadRequest()) { value in
                    self.alarm = value
                    print("Notification: alarm: \("\(self.alarm ?? .off)")")
                }
                try self.notifyRequest(self.profile.createLightingReadRequest()) { value in
                    self.lighting = value ?? .off
                    print("Notification: lighting: \("\(self.lighting)")")
                }
                try self.notifyRequest(self.profile.createModuleStateReadRequest()) { value in
                    self.moduleState = value ?? .off
                    print("Notification: module state: \("\(self.moduleState)")")
                }
                try self.notifyRequest(self.profile.createErrorCodeReadRequest()) { value in
                    self.errorCode = value ?? ErrorCode()
                    print("Notification: error code: \(self.errorCode)")
                }
                try self.notifyRequest(self.profile.createSpeedReadRequest()) { value in
                    self.speed = value ?? 0
                    print("Notification: speed: \(self.speed)")
                    if self.motionUnlock && self.lock == .locked {
                        Task {
                            print("Unlocking because of motion...")
                            try await self.setLocked(.unlocked)
                        }
                    }
                }
                try self.notifyRequest(self.profile.createDistanceReadRequest()) { value in
                    self.distance = value ?? 0.0
                    print("Notification: distance: \(self.distance)")
                }
                try self.notifyRequest(self.profile.createMuteSoundReadRequest()) { value in
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
