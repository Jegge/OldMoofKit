//
//  Assistance.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 12.08.23.
//

/// The level of motor assistance of the bike.
public enum MotorAssistance: UInt8 {
    /// The motor assistance is switched off.
    case off = 0
    /// The motor assistance is on level 1.
    case one = 1
    /// The motor assistance is on level 2.
    case two = 2
    /// The motor assistance is on level 3.
    case three = 3
    /// The motor assistance is on level 4.
    case four = 4
}
