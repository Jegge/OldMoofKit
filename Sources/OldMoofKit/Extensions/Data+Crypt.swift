import Foundation
import CommonCrypto

public enum CCryptError: Error {
    case success
    case paramError
    case bufferTooSmall
    case memoryFailure
    case alignmentError
    case decodeError
    case unimplemented
    case noResult
    case other(code: Int32)

    init (code: Int32) {
        switch code {
        case 0: self = .success
        case -4300: self = .paramError
        case -4301: self = .bufferTooSmall
        case -4302: self = .memoryFailure
        case -4303: self = .alignmentError
        case -4304: self = .decodeError
        case -4305: self = .unimplemented
        default: self = .other(code: code)
        }
    }
}

extension Data {
    private func pad(length: Int, value: UInt8 = 0) -> Data {
        if self.count < length {
            return self + Data(repeating: value, count: length - self.count)
        } else {
            return self
        }
    }

    private func crypt(operation: CCOperation, algorithm: CCAlgorithm, options: CCOptions, key: Data, data: Data) throws -> Data {
        let (status, result) = key.withUnsafeBytes { keyUnsafeRawBufferPointer in
            return data.withUnsafeBytes { dataUnsafeRawBufferPointer in
                let size = data.count + kCCBlockSizeAES128
                let buffer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 1)
                defer { buffer.deallocate() }
                var count: Int = 0
                let status = CCCrypt(operation, algorithm, options,
                        keyUnsafeRawBufferPointer.baseAddress, key.count,
                        nil,
                        dataUnsafeRawBufferPointer.baseAddress, data.count,
                        buffer, size, &count)
                return (status, status != kCCSuccess ? nil : Data(bytes: buffer, count: count))
            }
        }
        if status != kCCSuccess {
            throw CCryptError(code: status)
        }
        if result == nil {
            throw CCryptError.noResult
        }
        return result!
    }

    func encrypt_aes_ecb_zero(key: Data) throws -> Data {
        let padding = ((self.count + kCCBlockSizeAES128 - 1) / kCCBlockSizeAES128) * kCCBlockSizeAES128
        return try crypt(operation: CCOperation(kCCEncrypt),
                     algorithm: CCAlgorithm(kCCAlgorithmAES),
                         options: CCOptions(kCCOptionECBMode),
                           key: key,
                           data: self.pad(length: padding))
    }

    func decrypt_aes_ecb_zero(key: Data) throws -> Data {
        return try crypt(operation: CCOperation(kCCDecrypt),
                     algorithm: CCAlgorithm(kCCAlgorithmAES),
                       options: CCOptions(kCCOptionECBMode),
                           key: key,
                          data: self)
    }
}
