import Foundation

extension Data {
    init?(hexString: String) {
        var data = Data(capacity: hexString.count / 2)
        var index = hexString.startIndex

        while index < hexString.endIndex {
            if hexString[index].isWhitespace {
                index = hexString.index(after: index)
            } else if "0123456789abcdefABCDEF".contains(hexString[index]) {
                let byte = hexString[index...hexString.index(after: index)]
                guard var value = UInt8(byte, radix: 16) else {
                    return nil
                }
                data.append(&value, count: 1)
                index = hexString.index(index, offsetBy: 2)
            } else {
                return nil
            }
        }

        self = data
    }

    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}
