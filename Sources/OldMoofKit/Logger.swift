//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 02.09.23.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let bike = Logger(subsystem: subsystem, category: "bike")
    static let bluetooth = Logger(subsystem: subsystem, category: "bluetooth")
}
