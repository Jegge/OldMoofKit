//
//  File.swift
//  
//
//  Created by Sebastian Boettcher on 07.09.23.
//

import Foundation
import CommonCrypto

extension String {
    var isValidEncryptionKey: Bool {
        return (try? self.matchesRegex(pattern: "^[0-9A-Fa-f]{\(kCCKeySizeAES128 * 2)}$")) ?? false
    }

    var isValidMacAddress: Bool {
        return (try? self.matchesRegex(pattern: "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$")) ?? false
    }

    func matchesRegex (pattern: String) throws -> Bool {
        if #available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *) {
            let regex = try Regex(pattern)
            return !self.ranges(of: regex).isEmpty
        } else {
            let range = NSRange(location: 0, length: self.utf16.count)
            let regex = try NSRegularExpression(pattern: pattern)
            return regex.firstMatch(in: self, options: [], range: range) != nil
        }
    }
}
