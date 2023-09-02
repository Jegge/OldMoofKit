//
//  Region.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 20.08.23.
//

public enum Region: UInt8 {
    case invalid = 255
    case eu = 0         // 25 kmh
    case us = 1         // 32 kmh
    case offroad = 2    // 37 kmh
    case japan = 3      // 24 kmh
}
