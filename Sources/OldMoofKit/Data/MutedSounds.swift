//
//  SoundState.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 19.08.23.
//

public struct MutedSounds: OptionSet {
    public let rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public static let feedback = MutedSounds(rawValue: 1 << 0)
//    public static let unknown1 = MuteState(rawValue: 1 << 1) // long tick on unlock, long tick on lock
//    public static let unknown2 = MuteState(rawValue: 1 << 2) // long tick on lock
    public static let timer = MutedSounds(rawValue: 1 << 3) // no lockTimer
//      public static let unknown4 = MuteState(rawValue: 1 << 4) // long tick on unlock, short tick on lock
//      public static let unknown5 = MuteState(rawValue: 1 << 5) // very long tick on unlock, short tick on lock
//      public static let unknown6 = MuteState(rawValue: 1 << 6)
//      public static let unknown7 = MuteState(rawValue: 1 << 7)

    public static let lock = MutedSounds(rawValue: 1 << 8)
    public static let unlock = MutedSounds(rawValue: 1 << 9)
//    public static let unknownA = MuteState(rawValue: 1 << 10)
//    public static let unknownB = MuteState(rawValue: 1 << 11)
    public static let wakeup = MutedSounds(rawValue: 1 << 12)
    public static let sleep = MutedSounds(rawValue: 1 << 13)
//    public static let unknownE = MuteState(rawValue: 1 << 14)
//    public static let unknownF = MuteState(rawValue: 1 << 15)

    public static let all = MutedSounds([.feedback, .lock, .unlock, .wakeup, .sleep, .timer])
    public static let none = MutedSounds([])
    public static let moduleState = MutedSounds([.wakeup, .sleep])
    public static let lockState = MutedSounds([.lock, .unlock])
}

extension MutedSounds: CustomStringConvertible {
    public static var debugDescriptions: [(Self, String)] = [
        (.feedback, "feedback"),
        (.timer, "timer"),
        (.lock, "lock"),
        (.unlock, "unlock"),
        (.wakeup, "wakeup"),
        (.sleep, "sleep")
    ]

    public var description: String {
        if self == .none {
            return "none"
        } else {
            return Self.debugDescriptions.filter { contains($0.0) }.map { $0.1 }.joined(separator: ", ")
        }
    }
}
