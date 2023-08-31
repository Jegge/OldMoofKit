//
//  Data+Distance.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 28.08.23.
//

import Foundation

extension Data {
    var uint32: UInt32 {
       return self.withUnsafeBytes { $0.load(as: UInt32.self) }
   }
}
