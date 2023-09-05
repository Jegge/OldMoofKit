//
//  LightState.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 09.08.23.
//

/// The lighting mode of the bike.
public enum Lighting: UInt8 {
    /// The lights will switch on or off depending on the ambient light.
    case automatic = 0
    /// The lights will always be switched on.
    case alwaysOn = 1
    /// The lights will be switched off.
    case off = 2
}
