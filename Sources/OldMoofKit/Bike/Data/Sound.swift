//
//  Sound.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 19.08.23.
//

public enum Sound: UInt8 {
    case selection = 0x01
    case negativeBeep = 0x02
    case affirmativeBeep = 0x03
    case shortCountdown = 0x04
    case longCountdown = 0x05
    case beginDisarm = 0x06
    case bell = 0x07
    case horn = 0x08
    case lock = 0x09
    case unlock = 0x0A
    case alarm1 = 0x0B
    case alarm2 = 0x0C
    case wakeup = 0x0D
    case sleep = 0x0E
}
