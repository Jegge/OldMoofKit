//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 01.09.23.
//

import Foundation

/// The details of a bike, as read from the ``VanMoof`` api.
public struct BikeDetails: Codable {
    /// Creates the details for a bike based on it's properties.
    ///
    /// Parameter name: The name of the bike. This is a flavour text only.
    /// Parameter frameNumber: The frame number of the bike. This is a flavour text only.
    /// Parameter bleProfile: The name of the bluetooth low energy profile. This is crucial to connect a bike.
    /// Parameter modelName: The technical name of the model. This is flavour text only.
    /// Parameter macAddress: The MAC address of the bike. This is crucial to connect a bike.
    /// Parameter encryptionKey: The key used to encrypt the communication with the bike. This is crucial to connect a bike.
    /// Parameter smartModuleVersion: The version of the smart module. This is a flavour text only.
    public init(name: String, frameNumber: String, bleProfile: BleProfile, modelName: String, macAddress: String, encryptionKey: String, smartModuleVersion: String?) {
        self.name = name
        self.frameNumber = frameNumber
        self.bleProfile = bleProfile
        self.modelName = modelName
        self.macAddress = macAddress
        self.encryptionKey = encryptionKey
        self.smartModuleVersion = smartModuleVersion
    }

    /// The name of the bike (flavour text).
    public let name: String
    /// The frame number of the bike (flavour text).
    public let frameNumber: String
    /// The bluetooth low energy profile of the bike.
    public let bleProfile: BleProfile
    /// The technical model name of the bike (flavour text).
    public let modelName: String
    /// The MAC address of the bike.
    public let macAddress: String
    /// The key used to encrypt the communication with the bike.
    public let encryptionKey: String
    /// The smart module version (flavour text).
    public let smartModuleVersion: String?

    var deviceName: String {
        return "VANMOOF-\(macAddress.filter { $0 != ":" }.dropFirst(6))"
    }
}
