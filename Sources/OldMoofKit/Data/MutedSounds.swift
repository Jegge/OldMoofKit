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

    static let feedback = MutedSounds(rawValue: 1 << 0)
//    static let unknown1 = MuteState(rawValue: 1 << 1) // long tick on unlock, long tick on lock
//    static let unknown2 = MuteState(rawValue: 1 << 2) // long tick on lock
      static let timer = MutedSounds(rawValue: 1 << 3) // no lockTimer
//      static let unknown4 = MuteState(rawValue: 1 << 4) // long tick on unlock, short tick on lock
//      static let unknown5 = MuteState(rawValue: 1 << 5) // very long tick on unlock, short tick on lock
//      static let unknown6 = MuteState(rawValue: 1 << 6)
//      static let unknown7 = MuteState(rawValue: 1 << 7)

    static let lock = MutedSounds(rawValue: 1 << 8)
    static let unlock = MutedSounds(rawValue: 1 << 9)
//    static let unknownA = MuteState(rawValue: 1 << 10)
//    static let unknownB = MuteState(rawValue: 1 << 11)
    static let wakeup = MutedSounds(rawValue: 1 << 12)
    static let sleep = MutedSounds(rawValue: 1 << 13)
//    static let unknownE = MuteState(rawValue: 1 << 14)
//    static let unknownF = MuteState(rawValue: 1 << 15)

    static let all = MutedSounds([.feedback, .lock, .unlock, .wakeup, .sleep, .timer])
    static let none = MutedSounds([])
    static let moduleState = MutedSounds([.wakeup, .sleep])
    static let lockState = MutedSounds([.lock, .unlock])
}

extension MutedSounds: CustomStringConvertible {
    static public var debugDescriptions: [(Self, String)] = [
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
