//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 01.09.23.
//

import Foundation

public struct BikeConfiguration: Codable {

    init () {
        self.proximityUnlock = false
        self.motionUnlock = false
    }

    init(proximityUnlock: Bool, motionUnlock: Bool) {
        self.proximityUnlock = proximityUnlock
        self.motionUnlock = motionUnlock
    }

    public var proximityUnlock: Bool
    public var motionUnlock: Bool
}
