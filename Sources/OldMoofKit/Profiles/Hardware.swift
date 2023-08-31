//
//  Capabilites.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 27.08.23.
//

import Foundation

struct Hardware: OptionSet {
    let rawValue: Int

    static let elock = Hardware(rawValue: 1 << 0)
    static let alarm = Hardware(rawValue: 1 << 1)
    static let motor = Hardware(rawValue: 1 << 2)
    static let speaker = Hardware(rawValue: 1 << 3)
}
