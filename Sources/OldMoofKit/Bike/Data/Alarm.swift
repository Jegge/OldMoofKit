//
//  AlarmState.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 09.08.23.
//

// The alarm state of the bike.
public enum Alarm: UInt8 {
    // The anti-theft device is disabled.
    case off = 0
    // The anti-theft device has to be armed manually.
    case manual = 1
    // The bike will automatically arm the anti-theft device after a period of time.
    case automatic = 2
}
