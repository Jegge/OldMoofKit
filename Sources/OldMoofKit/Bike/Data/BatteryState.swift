//
//  BatteryState.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

/// The state of the battery. For bikes having a motor, this refers to the motor battery.
/// Otherwise, this refers to the module battery.
public enum BatteryState: UInt8 {
    /// The battery is currently discharging.
    case discharging = 0
    /// The battery is currently charging.
    case charging = 1
}
