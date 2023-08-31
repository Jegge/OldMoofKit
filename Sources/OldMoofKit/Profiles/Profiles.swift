//
//  Profiles.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 27.08.23.
//

public struct Profiles {
    private static let smartBike2016 = SmartBike2016Profile()
    private static let smartBike2018 = SmartBike2018Profile()
    private static let electrified2017 = Electified2017Profile()
    private static let electrified2018 = Electified2018Profile()

    // swiftlint:disable:next cyclomatic_complexity
    internal static func profile(named name: String) -> Profile? {
        switch name {
        case "SMARTBIKE_2016": return Profiles.smartBike2016            // SmartBike
        case "SMARTBIKE_2018": return Profiles.smartBike2018            // Smart S/X
        case "ELECTRIFIED_2016": return Profiles.electrified2017        // Electrified S/X
        case "ELECTRIFIED_2016_2017": return Profiles.electrified2017   // Electrified S/X
        case "ELECTRIFIED_2017": return Profiles.electrified2017        // Electrified S/X
        case "ELECTRIFIED_2018": return Profiles.electrified2018        // S2/X2
        case "ELECTRIFIED_2020": return nil                             // S3/X3
        case "ELECTRIFIED_2021": return nil                             // ???
        case "ELECTRIFIED_2022": return nil                             // S5/A5
        case "ELECTRIFIED_2023_TRACK1": return nil                      // ???
        case "ELECTRIFIED_2023_TRACK_1": return nil                     // ???
        default: return nil
        }
    }

    public static func supports(named name: String) -> Bool {
        return self.profile(named: name) != nil
    }
}
