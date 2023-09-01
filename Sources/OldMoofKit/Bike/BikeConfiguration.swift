//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 01.09.23.
//

import Foundation

struct BikeConfiguration: Codable {

    init () {
        self.proximityUnlock = false
        self.motionUnlock = false
    }

    init(proximityUnlock: Bool, motionUnlock: Bool) {
        self.proximityUnlock = proximityUnlock
        self.motionUnlock = motionUnlock
    }

    public let proximityUnlock: Bool
    public let motionUnlock: Bool
}
