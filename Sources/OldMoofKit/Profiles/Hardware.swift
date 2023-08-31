//
//  Capabilites.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 27.08.23.
//

import Foundation

public struct Hardware: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let elock = Hardware(rawValue: 1 << 0)
    public static let alarm = Hardware(rawValue: 1 << 1)
    public static let motor = Hardware(rawValue: 1 << 2)
    public static let speaker = Hardware(rawValue: 1 << 3)
}
