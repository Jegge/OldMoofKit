//
//  Bike.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 09.08.23.
//

import Foundation

public struct Bike: Codable {
    init (name: String, frameNumber: String, bleProfile: String, modelName: String, macAddress: String, key: Data, version: String?) {
        self.name = name
        self.frameNumber = frameNumber
        self.bleProfile = bleProfile
        self.modelName = modelName
        self.macAddress = macAddress
        self.key = key
        self.smartModuleVersion = version
        self.identifier = UUID(uuid: UUID_NULL)
    }

    init (bike: Bike, identifier: UUID) {
        self.name = bike.name
        self.frameNumber = bike.frameNumber
        self.bleProfile = bike.bleProfile
        self.modelName = bike.modelName
        self.macAddress = bike.macAddress
        self.key = bike.key
        self.smartModuleVersion = bike.smartModuleVersion
        self.identifier = identifier
    }

    let name: String
    let frameNumber: String
    let bleProfile: String
    let modelName: String
    let macAddress: String
    let key: Data
    let identifier: UUID
    let smartModuleVersion: String?

    var deviceName: String {
        return "VANMOOF-\(macAddress.filter { $0 != ":" }.dropFirst(6))"
    }
}

extension Bike: Equatable {
    public static func == (lhs: Bike, rhs: Bike) -> Bool {
        return lhs.macAddress == rhs.macAddress
    }
}
