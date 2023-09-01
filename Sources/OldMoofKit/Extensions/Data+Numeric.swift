//
//  Data+Distance.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 28.08.23.
//

import Foundation

extension Data {
    var uint32: UInt32 {
        return UInt32(self[0]) << 24 + UInt32(self[1]) << 16 + UInt32(self[2]) << 8 + UInt32(self[3])
       //&return self.withUnsafeBytes { $0.load(as: UInt32.self) }
   }
}
