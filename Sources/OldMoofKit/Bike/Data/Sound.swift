//
//  Sound.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 19.08.23.
//

/// A sound that the bike may play.
public enum Sound: UInt8 {
    /// Played when an option got selected.
    case selection = 0x01
    /// Played when an action turned out not ok.
    case negativeBeep = 0x02
    /// Played when an action turned out ok.
    case affirmativeBeep = 0x03
    /// Played when the timer ticks a countdown for a short period of time.
    case shortCountdown = 0x04
    /// Played when the timer ticks a countdown for a long period of time.
    case longCountdown = 0x05
    /// Played when beginning the manual disarm sequence.
    case beginDisarm = 0x06
    /// Played when using the bell (soft).
    case bell = 0x07
    /// Played when using the bell (hard).
    case horn = 0x08
    /// Played when the bike got locked.
    case lock = 0x09
    /// Played when the bike got unlocked.
    case unlock = 0x0A
    /// Played when the bike's anti-theft device triggers.
    case alarm1 = 0x0B
    /// Played when the bike's anti-theft device triggers.
    case alarm2 = 0x0C
    /// Played when the bike wakes up.
    case wakeup = 0x0D
    /// Played when the bike shuts down.
    case sleep = 0x0E
}
