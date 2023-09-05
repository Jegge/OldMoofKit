//
//  Capabilites.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 27.08.23.
//

import Foundation

/// Represents the hardware capabilities a bike may have.
public struct BikeHardware: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// This bike has an electronically disengaging, physical lock.
    public static let elock = BikeHardware(rawValue: 1 << 0)
    /// This bike has an automatic anti-theft device.
    public static let alarm = BikeHardware(rawValue: 1 << 1)
    /// This bike has a motor.
    public static let motor = BikeHardware(rawValue: 1 << 2)
    /// This bike has a speaker.
    public static let speaker = BikeHardware(rawValue: 1 << 3)
}
