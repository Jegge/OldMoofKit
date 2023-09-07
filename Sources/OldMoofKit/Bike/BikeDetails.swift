//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 01.09.23.
//

import Foundation

let bleProfileToBikeProfile: [BikeProfileName: BikeProfile] = [
    .smartBike2016: SmartBike2016Profile(),
    .smartBike2018: SmartBike2018Profile(),
    .electrified2016: Electified2017Profile(),
    .electrified20162017: Electified2017Profile(),
    .electrified2017: Electified2017Profile(),
    .electrified2018: Electified2018Profile()
]

/// The details of a bike, as read from the ``VanMoof`` api.
public struct BikeDetails: Codable {
    /// Creates the details for a bike based on it's properties.
    ///
    /// The parameters ``bleProfile``, ``macAddress`` and ``encryptionKey`` are crucial for a bluethooth scan or a connection to succeed.
    /// On the other hand ``name``, ``frameNumber``, ``modelName`` and ``smartModuleVersion`` are flavour text only and may be omitted.
    ///
    /// - Parameter bleProfile: The name of the bluetooth low energy profile.
    /// - Parameter macAddress: The MAC address of the bike.
    /// - Parameter encryptionKey: The key used to encrypt the communication with the bike.
    /// - Parameter name: The optional name of the bike.
    /// - Parameter frameNumber: The optional frame number of the bike.
    /// - Parameter modelName: The optional technical name of the model.
    /// - Parameter smartModuleVersion: The optional version of the smart module.
    ///
    /// - Throws: ``BikeError/macAddressInvalidFormat`` if the MAC address is not given in MAC-48 format.
    /// - Throws: ``BikeError/encryptionKeyInvalidFormat``if the encryption key is not given as 32 hexadecimal encoded bytes.
    public init(bleProfile: BikeProfileName, macAddress: String, encryptionKey: String,
                name: String = "VanMoof", frameNumber: String = "", modelName: String = "", smartModuleVersion: String? = nil) throws {
        if !macAddress.isValidMacAddress {
            throw BikeError.macAddressInvalidFormat
        }
        if !encryptionKey.isValidEncryptionKey {
            throw BikeError.encryptionKeyInvalidFormat
        }
        self.name = name
        self.frameNumber = frameNumber
        self.bleProfile = bleProfile
        self.modelName = modelName
        self.macAddress = macAddress
        self.encryptionKey = encryptionKey
        self.smartModuleVersion = smartModuleVersion
    }

    /// The bluetooth low energy profile of the bike.
    public let bleProfile: BikeProfileName
    /// The MAC address of the bike, in MAC-48 format.
    public let macAddress: String
    /// The key used to encrypt the communication with the bike.
    public let encryptionKey: String
    /// The name of the bike (flavour text).
    public let name: String
    /// The frame number of the bike (flavour text).
    public let frameNumber: String
    /// The technical model name of the bike (flavour text).
    public let modelName: String
    /// The smart module version (flavour text).
    public let smartModuleVersion: String?

    var deviceName: String {
        return "VANMOOF-\(macAddress.filter { $0 != ":" }.dropFirst(6))"
    }

    var profile: BikeProfile? {
        return bleProfileToBikeProfile[self.bleProfile]
    }

    /// Checks wether a bike is supported, based on it's ``bleProfile``.
    public var isSupported: Bool {
        return self.profile != nil
    }

    /// Retrieves the hardware capabilites of this bike, based on it's ``bleProfile``
    public var hardware: BikeHardware {
        return self.profile?.hardware ?? []
    }

    /// Retrieves a display friendly model name of this bike, based on it's ``bleProfile``.
    /// If this bike is not supported, the ``modelName`` will be returned instead.
    public var model: String {
        return self.profile?.model ?? self.modelName
    }
}
