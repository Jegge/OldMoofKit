//
//  ModuleState.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 10.08.23.
//

/// The module state of the bike.
public enum ModuleState: UInt8 {
    /// The bike is currently on.
    case on = 0
    /// The bike is currently off.
    case off = 1
    /// The bike is currently being shipped.
    case shipping = 2
    /// The bike is in standby.
    case standby = 3
    /// The bike's anti-theft device triggered once.
    case alarmOne = 4
    /// The bike's anti-theft device triggered twice.
    case alarmTwo = 5
    /// The bike's anti-theft device triggered thrice.
    case alarmThree = 6
    /// The bike is currenty sleeping.
    case sleeping = 7
    /// The bike is currently tracking.
    case tracking = 8
}
