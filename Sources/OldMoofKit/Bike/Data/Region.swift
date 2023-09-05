//
//  Region.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 20.08.23.
//

/// The region that this bike is currently located in. This implicitly sets the speed limit.
public enum Region: UInt8 {
    /// The European Union. Enforces a speed limit of 25 km/h.
    case eu = 0
    /// The United States of America. Enforces a speed limit of 32 km/h.
    case us = 1
    /// Offroad. Allows the maximum possible speed of 37 km/h.
    case offroad = 2
    /// Japan. Enforces a speed limit of 24 km/h.
    case japan = 3
}
