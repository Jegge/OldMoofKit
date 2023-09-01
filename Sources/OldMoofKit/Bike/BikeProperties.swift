//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 01.09.23.
//

import Foundation

public struct BikeProperties: Codable {
    public let name: String
    public let frameNumber: String
    public let bleProfile: String
    public let modelName: String
    public let macAddress: String
    public let key: Data
    public let smartModuleVersion: String?

    internal var deviceName: String {
        return "VANMOOF-\(macAddress.filter { $0 != ":" }.dropFirst(6))"
    }
}
