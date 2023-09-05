//
//  Profiles.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 27.08.23.
//

struct Profiles {
    static let smartBike2016 = SmartBike2016Profile()
    static let smartBike2018 = SmartBike2018Profile()
    static let electrified2017 = Electified2017Profile()
    static let electrified2018 = Electified2018Profile()
}

/// All valid bluetooth low energy profile names known up to date.
public enum BleProfile: LosslessStringConvertible, Hashable, Codable {
    // swiftlint:disable:next cyclomatic_complexity
    public init (_ rawValue: String) {
        switch rawValue.uppercased() {
        case "SMARTBIKE_2016": self = .smartBike2016
        case "SMARTBIKE_2018": self = .smartBike2018
        case "ELECTRIFIED_2016": self = .electrified2016
        case "ELECTRIFIED_2016_2017": self = .electrified20162017
        case "ELECTRIFIED_2017": self = .electrified2017
        case "ELECTRIFIED_2018": self = .electrified2018
        case "ELECTRIFIED_2020": self = .electrified2020
        case "ELECTRIFIED_2021": self = .electrified2021
        case "ELECTRIFIED_2022": self = .electrified2022
        case "ELECTRIFIED_2023_TRACK1": self = .electrified2023track1a
        case "ELECTRIFIED_2023_TRACK_1": self = .electrified2023track1b
        default: self = .unknownName(rawValue.uppercased())
        }
    }

    public var description: String {
        switch self {
        case .smartBike2016: return "SMARTBIKE_2016"
        case .smartBike2018: return "SMARTBIKE_2018"
        case .electrified2016: return "ELECTRIFIED_2016"
        case .electrified20162017: return "ELECTRIFIED_2016_2017"
        case .electrified2017: return "ELECTRIFIED_2017"
        case .electrified2018: return "ELECTRIFIED_2018"
        case .electrified2020: return "ELECTRIFIED_2020"
        case .electrified2021: return "ELECTRIFIED_2021"
        case .electrified2022: return "ELECTRIFIED_2022"
        case .electrified2023track1a: return "ELECTRIFIED_2023_TRACK1"
        case .electrified2023track1b: return "ELECTRIFIED_2023_TRACK_1"
        case .unknownName(let name): return name.uppercased()
        }
    }

    /// The ble profile of a SmartBike
    case smartBike2016
    /// The ble profile of a Smart S or Smart X
    case smartBike2018
    /// The ble profile of an Electrified S or Electrified X (2016)
    case electrified2016
    /// The ble profile of an Electrified S or Electrified X (2016 - 2017)
    case electrified20162017
    /// The ble profile of an Electrified S or Electrified X (2017)
    case electrified2017
    /// The ble profile of an S2 or X2
    case electrified2018
    /// The ble profile of an S3 or X3
    case electrified2020
    /// The ble profile of an unknown bike
    case electrified2021
    /// The ble profile of an unknown bike
    case electrified2022
    /// The ble profile of an unknown bike
    case electrified2023track1a
    /// The ble profile of an unknown bike
    case electrified2023track1b
    /// The ble profile of an unknown bike
    case unknownName(_ name: String)
}

extension BikeDetails {
    static let bleProfileToBikeProfile: [BleProfile: BikeProfile] = [
        .smartBike2016: Profiles.smartBike2016,
        .smartBike2018: Profiles.smartBike2018,
        .electrified2016: Profiles.electrified2017,
        .electrified20162017: Profiles.electrified2017,
        .electrified2017: Profiles.electrified2017,
        .electrified2018: Profiles.electrified2018
    ]

    var profile: BikeProfile? {
        return BikeDetails.bleProfileToBikeProfile[self.bleProfile]
    }

    /// Checks wether a bike is supported, based on it's ``bleProfile``.
    public var isSupported: Bool {
        return self.profile != nil
    }

    /// Retrieves the hardware capabilites of this bike, based on it's ``bleProfile``
    public var hardware: BikeHardware {
        return self.profile?.hardware ?? []
    }

    /// Retrieves a display friendly model name of this bike, based on it's ``bleProfile``.
    /// If this bike is not supported, the ``modelName`` will be returned instead.
    public var model: String {
        return self.profile?.model ?? self.modelName
    }
}
