//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 01.09.23.
//

import Foundation

public struct BikeDetails: Codable {
    public init(name: String, frameNumber: String, bleProfile: String, modelName: String, macAddress: String, encryptionKey: String, smartModuleVersion: String?) {
        self.name = name
        self.frameNumber = frameNumber
        self.bleProfile = bleProfile
        self.modelName = modelName
        self.macAddress = macAddress
        self.encryptionKey = encryptionKey
        self.smartModuleVersion = smartModuleVersion
    }

    public let name: String
    public let frameNumber: String
    public let bleProfile: String
    public let modelName: String
    public let macAddress: String
    public let encryptionKey: String
    public let smartModuleVersion: String?

    internal var deviceName: String {
        return "VANMOOF-\(macAddress.filter { $0 != ":" }.dropFirst(6))"
    }
}
