//
//  ReadRequest.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 30.08.23.
//

import CoreBluetooth

struct ReadRequest<T> {
    let uuid: CBUUID
    let decrypt: Bool
    let parse: ((Data?) -> T?)
}
