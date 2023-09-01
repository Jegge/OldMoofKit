//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 01.09.23.
//

import CoreBluetooth

struct WriteRequest {
    let uuid: CBUUID
    let command: UInt8?
    let data: Data
}
