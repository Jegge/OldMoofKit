//
//  UnitState.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 20.08.23.
//

/// The measuring unit used for ``Bike/speed`` and ``Bike/distance``.
public enum Unit: UInt8 {
    /// The bike's ``Bike/speed`` is measured in km/h and ``Bike/distance`` is measured in km.
    case metric = 0
    /// The bike's ``Bike/speed`` is measured in mph and ``Bike/distance`` is measured in miles.
    case imperial = 1
}
