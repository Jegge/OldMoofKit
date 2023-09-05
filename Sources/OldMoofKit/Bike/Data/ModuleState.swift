//
//  ModuleState.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 10.08.23.
//

public enum ModuleState: UInt8 {
    case on = 0
    case off = 1
    case shipping = 2
    case standby = 3
    case alarmOne = 4
    case alarmTwo = 5
    case alarmThree = 6
    case sleeping = 7
    case tracking = 8
}
