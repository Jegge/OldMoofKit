//
//  BikeConnection.swift
//  VanMoofTest
//
//  Created by Sebastian Boettcher on 09.08.23.
//

import CoreBluetooth
import Combine
import OSLog

/// A connectable bike.
public final class Bike: Codable {
    enum CodingKeys: String, CodingKey {
        case identifier
        case details
    }

    /// The identifier of the bluetooth device. Used to reestablish a connection to a previously connected device.
    public let identifier: UUID
    /// The details of the bike.
    public let details: BikeDetails

    /// Subscribe this publisher to get informed about changes of this bike's ``state``.
    public let statePublisher = PassthroughSubject<BikeState, Never>()
    /// Subscribe this publisher to get informed about errors that may occur.
    /// 
    /// These errors do not stem from the bike, but rather from within this api. 
    /// To get informed about the bike's error codes, use ``errorCodePublisher``.
    public let errorPublisher = PassthroughSubject<Error, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``lock``.
    public let lockPublisher = PassthroughSubject<Lock, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``alarm``.
    public let alarmPublisher = PassthroughSubject<Alarm, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``lighting``.
    public let lightingPublisher = PassthroughSubject<Lighting, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``batteryLevel``.
    public let batteryLevelPublisher = PassthroughSubject<Int, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``batteryState``.
    public let batteryStatePublisher = PassthroughSubject<BatteryState, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``moduleState``.
    public let moduleStatePublisher = PassthroughSubject<ModuleState, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``errorCode``.
    ///
    /// This error code stems from the bike. To get informed about errors coming from within this api,
    /// use ``errorPublisher`` instead.
    public let errorCodePublisher = PassthroughSubject<ErrorCode, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``motorAssistance``.
    public let motorAssistancePublisher = PassthroughSubject<MotorAssistance, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``mutedSounds``.
    public let mutedSoundsPublisher = PassthroughSubject<MutedSounds, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``speed``.
    public let speedPublisher = PassthroughSubject<Int, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``distance``.
    public let distancePublisher = PassthroughSubject<Double, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``region``.
    public let regionPublisher = PassthroughSubject<Region, Never>()
    /// Subscribe this publisher to get informed about changes of this bike's ``unit``.
    public let unitPublisher = PassthroughSubject<Unit, Never>()

    private var key: Data
    private var profile: BikeProfile
    private var connection: BluetoothConnectionProtocol
    private var bluetoothState: AnyCancellable?
    private var bluetoothErrors: AnyCancellable?
    private var bluetoothNotifications: AnyCancellable?
    private var notificationCallbacks: [CBUUID: ((Data?) -> Void)] = [:]

    /// The current state of the bike.
    public var state: BikeState {
        return self.connection.isConnected == true ? .connected : .disconnected
    }

    /// The current bluetooth signal strength of the bike.
    public var signalStrength: Int {
        get async {
            return (try? await self.connection.readRssi()) ?? -1
        }
    }

    /// The current lock state of the bike. Can be set with ``set(lock:)``.
    private (set) public var lock: Lock = .locked {
        didSet {
            self.lockPublisher.send(self.lock)
        }
    }

    /// The current alarm of the bike. Can be set with ``set(alarm:)``.
    ///
    /// If your bike does not support an alarm, this value will be `nil`.
    private (set) public var alarm: Alarm? {
        didSet {
            if let alarm = self.alarm {
                self.alarmPublisher.send(alarm)
            }
        }
    }

    /// The current lighting mode of the bike. Can be set with ``set(lighting:)``.
    private (set) public var lighting: Lighting = .off {
        didSet {
            self.lightingPublisher.send(self.lighting)
        }
    }

    /// The current battery level of the bike in percent.
    ///
    /// Refers to the motor battery in bikes that do have a motor, otherwise refers to the module battery.
    private (set) public var batteryLevel: Int = 0 {
        didSet {
            self.batteryLevelPublisher.send(self.batteryLevel)
        }
    }

    /// The current battery state of the bike.
    ///
    /// Refers to the motor battery in bikes that do have a motor, otherwise refers to the module battery.
    private (set) public var batteryState: BatteryState = .discharging {
        didSet {
            self.batteryStatePublisher.send(self.batteryState)
        }
    }

    /// The current module state of the bike.
    /// 
    /// If the bike is in standy, use ``wakeup()`` to wake it up.
    private (set) public var moduleState: ModuleState = .off {
        didSet {
            self.moduleStatePublisher.send(self.moduleState)
        }
    }

    /// The current error code of the bike.
    private (set) public var errorCode: ErrorCode = ErrorCode() {
        didSet {
            self.errorCodePublisher.send(self.errorCode)
        }
    }

    /// The current motor assistance level of the bike.
    ///
    /// If your bike does not have a motor, this value will be `nil`.
    private (set) public var motorAssistance: MotorAssistance? {
        didSet {
            if let motorAssistance = self.motorAssistance {
                self.motorAssistancePublisher.send(motorAssistance)
            }
        }
    }

    /// The currently muted sounds of the bike.
    ///
    /// If your bike does not have a speaker, this value will always be empty.
    private (set) public var mutedSounds: MutedSounds = [] {
        didSet {
            self.mutedSoundsPublisher.send(self.mutedSounds)
        }
    }

    /// The current speed in km/h of the bike.
    private (set) public var speed: Int = 0 {
        didSet {
            self.speedPublisher.send(self.speed)
        }
    }

    /// The currently travelled distance in hectometers of the bike.
    private (set) public var distance: Double = 0 {
        didSet {
            self.distancePublisher.send(self.distance)
        }
    }

    /// The current region of the bike.
    ///
    /// This region is relevant to limit the maximum speed your bike will provide you motor
    /// assistance for. Setting the region of your e-bike to a value not corresponding to your 
    /// country may be illegal in some jurisdictions. Use at your own risk.
    /// If your bike does not have a motor, this value will be `nil`.
    private (set) public var region: Region? {
        didSet {
            if let region = self.region {
                self.regionPublisher.send(region)
            }
        }
    }

    /// The current unit of the bike.
    ///
    /// Defines wether speed and distance should be converted into mph.
    private (set) public var unit: Unit? {
        didSet {
            if let unit = self.unit {
                self.unitPublisher.send(unit)
            }
        }
    }

    private init (connection: BluetoothConnectionProtocol, identifier: UUID, details: BikeDetails, profile: BikeProfile) {
        self.connection = connection
        self.identifier = identifier
        self.details = details
        self.profile = profile
        self.key = Data(hexString: details.encryptionKey) ?? Data()
    }

    /// Creates a new bike instance by decoding from the given decoder.
    ///
    /// - Parameters decoder: The decoder to read data from.
    ///
    /// - Throws: ``BikeError/bikeNotSupported`` if the requested bike model is not supported.
    public convenience init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(UUID.self, forKey: .identifier)
        let details = try container.decode(BikeDetails.self, forKey: .details)
        guard let profile = details.profile else {
            throw BikeError.bikeNotSupported
        }
        let connection = BluetoothConnection(identifier: identifier, reconnectInterval: 1)
        self.init(connection: connection, identifier: identifier, details: details, profile: profile)
    }

    /// Performs a bluetooth scan for a device matching the provided details and returns a connectable bike.
    ///
    /// - Parameter details: The details describe the bike we are looking for.
    /// - Parameter timeout: The timeout allows us to abort the bluetooth scan after a specified time period.
    ///
    /// - Returns: A connectable bike.
    ///
    /// - Throws: ``BikeError/bikeNotSupported`` if the requested bike model is not supported.
    /// - Throws: ``BluetoothError/timeout`` if the bike could not be found via bluetooth in the specified time period.
    /// - Throws: ``BluetoothError/poweredOff`` if bluetooth is currently switched off.
    /// - Throws: ``BluetoothError/unauthorized`` if the app is not authorized to use bluetooth in the app settings.
    /// - Throws: ``BluetoothError/unsupported`` if your device does not support bluetooth.
    public convenience init (scanningForBikeMatchingDetails details: BikeDetails, timeout seconds: TimeInterval = 30) async throws {
        guard let profile = details.profile else {
            throw BikeError.bikeNotSupported
        }
        let scanner = BluetoothScanner()
        let identifier = try await scanner.scanForPeripherals(withServices: [profile.identifier], name: details.deviceName, timeout: seconds)
        let connection = BluetoothConnection(identifier: identifier, reconnectInterval: 1)
        self.init(connection: connection, identifier: identifier, details: details, profile: profile)
    }

    /// Encodes this bike to a given encoder.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.details, forKey: .details)
    }

    private func readRequest<T> (_ request: ReadRequest<T>?) async throws -> T? {
        guard let request = request else {
            return nil
        }
        guard self.state == .connected else {
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
        guard self.state == .connected else {
            throw BikeError.notConnected
        }

        let challenge = try await self.readRequest(self.profile.makeChallengeReadRequest())
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
        guard self.state == .connected else {
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
        Logger.bike.info("Authenticating...")
        try await self.writeRequest(self.profile.makeAuthenticationWriteRequest(key: self.key))

        Logger.bike.info("Reading parameters...")
        if let parameters = try await self.readRequest(self.profile.makeParametersReadRequest()) {
            Logger.bike.trace("Parameters:\n\(parameters.description)")
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
        if let moduleBatteryLevel = try await self.readRequest(self.profile.makeBatteryLevelReadRequest()) {
            Logger.bike.trace("Module battery level: \(moduleBatteryLevel)%")
            self.batteryLevel = moduleBatteryLevel
        }
        if let lock = try await self.readRequest(self.profile.makeLockReadRequest()) {
            Logger.bike.trace("Lock: \(String(describing: lock))")
            self.lock = lock
        }
        if let alarm = try await self.readRequest(self.profile.makeAlarmReadRequest()) {
            Logger.bike.trace("Alarm: \(String(describing: alarm))")
            self.alarm = alarm
        }
        if let lighting = try await self.readRequest(self.profile.makeLightingReadRequest()) {
            Logger.bike.trace("Lighting: \(String(describing: lighting))")
            self.lighting = lighting
        }
        if let moduleState = try await self.readRequest(self.profile.makeModuleStateReadRequest()) {
            Logger.bike.trace("Module state: \(String(describing: moduleState))")
            self.moduleState = moduleState
        }
        if let mutedSounds = try await self.readRequest(self.profile.makeMuteSoundReadRequest()) {
            Logger.bike.trace("Muted sounds: \(mutedSounds.description))")
            self.mutedSounds = mutedSounds
        }
        if let errorCode = try await self.readRequest(self.profile.makeErrorCodeReadRequest()) {
            Logger.bike.trace("ErrorCode: \(errorCode)")
            self.errorCode = errorCode
        }
        if let distance = try await self.readRequest(self.profile.makeDistanceReadRequest()) {
            Logger.bike.trace("Distance: \(distance) km")
            self.distance = distance
        }
        if let batteryState = try await self.readRequest(self.profile.makeBatteryStateReadRequest()) {
            Logger.bike.trace("BatteryState: \(String(describing: batteryState))")
            self.batteryState = batteryState
        }

        Logger.bike.info("Starting notifications...")
        try self.notifyRequest(profile.makeParametersReadRequest()) { parameters in
            Logger.bike.trace("Notification: parameters:\n\(parameters.description)")
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
        try? self.notifyRequest(profile.makeBatteryLevelReadRequest()) { value in
            Logger.bike.trace("Notification: battery level: \(value)%")
            self.batteryLevel = value
        }
        try self.notifyRequest(profile.makeBatteryStateReadRequest()) { value in
            Logger.bike.trace("Notification: battery charging: \(String(describing: value))")
            self.batteryState = value
        }
        try self.notifyRequest(profile.makeLockReadRequest()) { value in
            Logger.bike.trace("Notification: lock: \(String(describing: value))")
            self.lock = value
        }
        try self.notifyRequest(profile.makeAlarmReadRequest()) { value in
            Logger.bike.trace("Notification: alarm: \(String(describing: value))")
            self.alarm = value
        }
        try self.notifyRequest(profile.makeLightingReadRequest()) { value in
            Logger.bike.trace("Notification: lighting: \(String(describing: value))")
            self.lighting = value
        }
        try self.notifyRequest(profile.makeModuleStateReadRequest()) { value in
            Logger.bike.trace("Notification: module state: \(String(describing: value))")
            self.moduleState = value
        }
        try self.notifyRequest(profile.makeErrorCodeReadRequest()) { value in
            Logger.bike.trace("Notification: error code: \(value)")
            self.errorCode = value
        }
        try self.notifyRequest(profile.makeSpeedReadRequest()) { value in
            Logger.bike.trace("Notification: speed: \(value)")
            self.speed = value
        }
        try self.notifyRequest(profile.makeDistanceReadRequest()) { value in
            Logger.bike.trace("Notification: distance: \(value) km")
            self.distance = value
        }
        try self.notifyRequest(profile.makeMuteSoundReadRequest()) { value in
            Logger.bike.trace("Notification: muted sounds: \(value)")
            self.mutedSounds = value
        }
    }

    /// Wakes the bike from it's sleep state, if required.
    ///
    /// Does nothing if the bike's `moduleState` is not `.standy`.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func wakeup () async throws {
        if self.moduleState == .standby {
            Logger.bike.info("Waking the bike up!")
            try await self.writeRequest(self.profile.makeModuleStateWriteRequest(value: .on))
            try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
        }
    }

    /// Sets the current ``lock`` state of the bike.
    ///
    /// This change is directly transmitted to the bike, and ``lock`` will automatically 
    /// update upon receiving an appropriate bluetooth notification.
    ///
    /// Depending on your bike, this will either lock or unlock your bike, or initiate a lock
    /// request, where some physical activity on the bike has to be performed to unlock it.
    ///
    /// - Parameter lock: The new value to set.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func set (lock value: Lock) async throws {
        Logger.bike.info("Setting lock to \(String(describing: value))")
        try await self.writeRequest(self.profile.makeLockWriteRequest(value: value))
    }

    /// Sets the current ``lighting`` mode of the bike.
    ///
    /// This change is directly transmitted to the bike, and ``lighting`` will automatically 
    /// update upon receiving an appropriate bluetooth notification.
    ///
    /// - Parameter lighting: The new value to set.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func set (lighting value: Lighting) async throws {
        Logger.bike.info("Setting lighting to \(String(describing: value))")
        try await self.writeRequest(self.profile.makeLightingWriteRequest(value: value))
    }

    /// Sets the current ``alarm`` mode of the bike.
    ///
    /// This change is directly transmitted to the bike, and ``alarm`` will automatically 
    /// update upon receiving an appropriate bluetooth notification.
    ///
    /// - Parameter alarm: The new value to set.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func set (alarm value: Alarm) async throws {
        Logger.bike.info("Setting alarm to \(String(describing: value))")
        try await self.writeRequest(self.profile.makeAlarmWriteRequest(value: value))
    }

    /// Sets the current ``motorAssistance`` level of the bike.
    ///
    /// This change is directly transmitted to the bike, and ``motorAssistance`` will automatically 
    /// update upon receiving an appropriate bluetooth notification.
    ///
    /// Also sets the current ``region`` of the bike. If the current ``region`` is `nil`, this call gets ignored.
    ///
    /// - Parameter motorAssistance: The new value to set.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func set (motorAssistance value: MotorAssistance) async throws {
        Logger.bike.info("Setting motor assistance to \(String(describing: value))")
        if let region = self.region {
            try await self.writeRequest(self.profile.makeMotorAssistanceWriteRequest(value: value, region: region))
        }
    }

    /// Sets the current ``region`` of the bike.
    ///
    /// This change is directly transmitted to the bike, and ``region`` will automatically 
    /// update upon receiving an appropriate bluetooth notification.
    ///
    /// Also sets the current ``motorAssistance`` of the bike. If the current ``motorAssistance`` is `nil`, this call gets ignored.
    ///
    /// - Parameter region: The new value to set.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func set (region value: Region) async throws {
        Logger.bike.info("Setting region to \(String(describing: value))")
        if let motorAssistance = self.motorAssistance {
            try await self.writeRequest(self.profile.makeMotorAssistanceWriteRequest(value: motorAssistance, region: value))
        }
    }

    /// Sets the current ``unit`` of the bike.
    ///
    /// This change is directly transmitted to the bike, and ``unit`` will automatically 
    /// update upon receiving an appropriate bluetooth notification.
    ///
    /// - Parameter unit: The new value to set.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func set (unit value: Unit) async throws {
        Logger.bike.info("Setting unit to \(String(describing: value))")
        try await self.writeRequest(self.profile.makeUnitWriteRequest(value: value))
    }

    /// Sets the current ``mutedSounds`` of the bike.
    ///
    /// This change is directly transmitted to the bike, and ``mutedSounds`` will automatically 
    /// update upon receiving an appropriate bluetooth notification.
    ///
    /// - Parameter mutedSounds: The new value to set.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func set (mutedSounds value: MutedSounds) async throws {
        Logger.bike.info("Setting muted sounds to \(value.description)")
        try await self.writeRequest(self.profile.makeMutedSoundsWriteRequest(value: value))
    }

    /// Plays a sound a given number of times via the bike's speaker.
    ///
    /// If the bike has no speaker, this call will do nothing. As not all bikes support
    /// all sounds, this call may have no effect.
    ///
    /// - Parameter sound: The sound to play. Depending on your bike, this sound may not be heard.
    /// - Parameter cound: How often this sound is played.
    ///
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func playSound (_ sound: Sound, repeat count: UInt8 = 1) async throws {
        Logger.bike.info("Playing sound \(String(describing: sound)) \(count) times.")
        try await self.writeRequest(self.profile.makePlaySoundWriteRequest(sound: sound, repeats: count))
    }

    /// Sets the backup code used to unlock your bike without a bluetooth connection.
    ///
    /// If the bike has no speaker, this call will do nothing. As not all bikes support
    /// all sounds, this call may have no effect.
    ///
    /// - Parameter code: The code to use. The allowed range is 111 up to 999 inclusive, but it may not contain the digit 0.
    ///
    /// - Throws: ``BikeError/pinCodeInvalid`` if the code is not valid.
    /// - Throws: ``BikeError/notConnected`` if the bike currently not connected.
    public func set (backupCode code: Int) async throws {
        if code < 111 || code > 999 {
            throw BikeError.pinCodeInvalid
        }
        if String(code, radix: 10).contains("0") {
            throw BikeError.pinCodeInvalid
        }
        Logger.bike.info("Setting backup code to \(code).")
        try await self.writeRequest(self.profile.makeBackupCodeWriteRequest(code: code))
    }

    /// Connects the bike.
    ///
    /// The connection will be held and automatically restored should it drop until ``disconnect()`` got called.
    /// If the connection is already established, this call will have no effect.
    /// 
    /// - Throws: ``BluetoothError/busy`` if the bike is currently trying to connect.
    /// - Throws: ``BluetoothError/peripheralNotFound`` if the peripheral is unknown. In this case, try to re-initialize
    ///           the bike again by construction a new one with ``init(scanningForBikeMatchingDetails:timeout:)``
    /// - Throws: ``BluetoothError/timeout`` if the bike could not be found via bluetooth in the specified time period.
    /// - Throws: ``BluetoothError/poweredOff`` if bluetooth is currently switched off.
    /// - Throws: ``BluetoothError/unauthorized`` if the app is not authorized to use bluetooth in the app settings.
    /// - Throws: ``BluetoothError/unsupported`` if your device does not support bluetooth.
    public func connect () async throws {
        if self.connection.isConnected {
            return
        }

        self.bluetoothState = self.connection.state.sink { state in
            switch state {
            case .connected:
                Task {
                    do {
                        try await self.setupConnection()
                        Logger.bike.info("Bike connected...")
                        self.statePublisher.send(.connected)
                    } catch {
                        self.errorPublisher.send(error)
                    }
                }

            case .disconnected:
                self.notificationCallbacks = [:]
                self.statePublisher.send(.disconnected)
                Logger.bike.info("Bike disconnected...")
            }
        }

        self.bluetoothErrors = self.connection.errors.sink { error in
            self.errorPublisher.send(error)
        }

        self.bluetoothNotifications = self.connection.notifications.sink { notification in
            self.notificationCallbacks[notification.uuid]?(notification.data)
        }

        try await self.connection.connect()
    }

    /// Disconnects the bike.
    ///
    /// The connection will shut down and no further automatic re-connection will be attempted.
    public func disconnect () {
        self.connection.disconnect()
        self.bluetoothState?.cancel()
        self.bluetoothErrors?.cancel()
        self.bluetoothNotifications?.cancel()
        self.bluetoothState = nil
        self.bluetoothErrors = nil
        self.bluetoothNotifications = nil
    }
}
