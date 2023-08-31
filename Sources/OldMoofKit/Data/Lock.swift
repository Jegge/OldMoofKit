//
//  Lock.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import Foundation

public enum Lock: UInt8 {
    case unlocked = 0
    case locked = 1
    case awaitingUnlock = 2

    func toggle () -> Lock {
        return (self == .locked) ? .unlocked : .locked
    }
}
