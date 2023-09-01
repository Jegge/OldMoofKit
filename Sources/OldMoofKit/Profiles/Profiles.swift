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

extension BikeProperties {
    internal var profile: Profile? {
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

    public var isSupported: Bool {
        return self.profile != nil
    }
}
