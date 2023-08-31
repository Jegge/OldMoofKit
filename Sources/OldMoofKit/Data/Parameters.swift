//
//  ParametersState.swift
//  VanMoofKey
//
//  Created by Sebastian Boettcher on 19.08.23.
//

import Foundation

internal struct Parameters: CustomStringConvertible {
    let data: Data?
    let alarm: Alarm?
    let moduleState: ModuleState
    let lock: Lock
    let batteryState: BatteryState
    let speed: Int
    let motorBatteryLevel: Int?
    let moduleBatteryLevel: Int
    let lighting: Lighting
    let unit: Unit?
    let motorAssistance: MotorAssistance?
    let region: Region?
    let mutedSounds: MutedSounds
    let distance: Double
    let errorCode: ErrorCode

    var description: String {
        let motorAssistance = self.motorAssistance == nil ? "-" : "\(self.motorAssistance!)"
        let alarm = self.alarm == nil ? "-" : "\(self.alarm!)"
        let region = self.region == nil ? "-" : "\(self.region!)"
        let unit = self.unit == nil ? "-" : "\(self.unit!)"
        let motorBatteryLevel = self.motorBatteryLevel == nil ? "-" : "\(self.motorBatteryLevel!)%"
        return
            "  * Raw Data: \(self.data?.hexString ?? "-") \n" +
            "  * Lock: \(self.lock)\n" +
            "  * Battery state: \(self.batteryState)\n" +
            "  * Module state: \(self.moduleState)\n" +
            "  * Error code: \(self.errorCode)\n" +
            "  * Motor assistance: \(motorAssistance)\n" +
            "  * Muted sounds: \(self.mutedSounds)\n" +
            "  * Speed: \(self.speed)\n" +
            "  * Distance: \(self.distance)\n" +
            "  * Region: \(region)\n" +
            "  * Unit: \(unit)\n" +
            "  * Module battery level: \(self.moduleBatteryLevel)%\n" +
            "  * Motor battery level: \(motorBatteryLevel)\n" +
            "  * Light: \(self.lighting)\n" +
            "  * Alarm: \(alarm)\n"
    }
}
