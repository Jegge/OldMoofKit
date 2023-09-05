//
//  Lock.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

/// The lock state of the bike.
public enum Lock: UInt8 {
    /// The bike is currently unlocked.
    case unlocked = 0
    /// The bike is currently locked.
    case locked = 1
    /// The bike is triggered to unlock and is awaiting physical user interaction.
    case awaitingUnlock = 2

    /// Creates a complementary lock state.
    public func toggle () -> Lock {
        return (self == .locked) ? .unlocked : .locked
    }
}
