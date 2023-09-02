//
//  ErrorCode.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 10.08.23.
//

import Foundation

public struct ErrorCode: CustomStringConvertible, Equatable {

    let data: Data

    init() {
        self.data = Data()
    }

    init(code: UInt8) {
        self.data = Data([code])
    }
    init(rawData: Data) {
        self.data = rawData
    }

    public var description: String {
        switch self {
        case .noError: return "no error"
        case .motorStalled: return "motor stalled"
        case .overVoltage: return "over voltage"
        case .underVoltage: return "under voltage"
        case .motorFast: return "motor fast"
        case .overCurrent: return "over current"
        case .torqueAbnormal: return "torque abnormal"
        case .torqueInitialAbnormal: return "torque initial abnormal"
        case .overTemperature: return "over temperature"
        case .hallArrangementMismatch: return "hall arrangement mismatch"
        case .i2cBusError: return "i2c bus error"
        case .gsmUartTimeout: return "gsm uart timeout"
        case .controllerUartTimeout: return "controller uart timeout"
        case .gsmRegistrationFailure: return "gsm registration failure"
        case .noBatteryOutput: return "no battery output"
        default: return self.data.hexString
        }
    }

    static let noError = ErrorCode(rawData: Data([0]))
    static let motorStalled = ErrorCode(rawData: Data([1]))
    static let overVoltage = ErrorCode(rawData: Data([2]))
    static let underVoltage = ErrorCode(rawData: Data([3]))
    static let motorFast = ErrorCode(rawData: Data([4]))
    static let overCurrent = ErrorCode(rawData: Data([6]))
    static let torqueAbnormal = ErrorCode(rawData: Data([7]))
    static let torqueInitialAbnormal = ErrorCode(rawData: Data([8]))
    static let overTemperature = ErrorCode(rawData: Data([9]))
    static let hallArrangementMismatch = ErrorCode(rawData: Data([16]))
    static let i2cBusError = ErrorCode(rawData: Data([25]))
    static let gsmUartTimeout = ErrorCode(rawData: Data([26]))
    static let controllerUartTimeout = ErrorCode(rawData: Data([27]))
    static let gsmRegistrationFailure = ErrorCode(rawData: Data([28]))
    static let noBatteryOutput = ErrorCode(rawData: Data([29]))
}
