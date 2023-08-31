//
//  ReadRequest.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import CoreBluetooth

extension BikeConnection {
    struct ReadRequest<T> {
        let uuid: CBUUID
        let decrypt: Bool
        let parse: ((Data?) -> T?)
    }

    struct WriteRequest {
        let uuid: CBUUID
        let command: UInt8?
        let data: Data
    }
}
