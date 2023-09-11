import Foundation
import CommonCrypto

enum CCryptError: Error {
    case success
    case paramError
    case bufferTooSmall
    case memoryFailure
    case alignmentError
    case decodeError
    case unimplemented
    case overflow
    case rngFailure
    case unspecified
    case callSequence
    case keySize
    case invalidKey
    case noResult

    // swiftlint:disable:next cyclomatic_complexity
    init (cryptorStatus: CCCryptorStatus) {
        switch cryptorStatus {
        case CCCryptorStatus(kCCSuccess): self = .success
        case CCCryptorStatus(kCCParamError): self = .paramError
        case CCCryptorStatus(kCCBufferTooSmall): self = .bufferTooSmall
        case CCCryptorStatus(kCCMemoryFailure): self = .memoryFailure
        case CCCryptorStatus(kCCAlignmentError): self = .alignmentError
        case CCCryptorStatus(kCCDecodeError): self = .decodeError
        case CCCryptorStatus(kCCUnimplemented): self = .unimplemented
        case CCCryptorStatus(kCCOverflow): self = .overflow
        case CCCryptorStatus(kCCRNGFailure): self = .rngFailure
        case CCCryptorStatus(kCCUnspecifiedError): self = .unspecified
        case CCCryptorStatus(kCCCallSequenceError): self = .callSequence
        case CCCryptorStatus(kCCKeySizeError): self = .keySize
        case CCCryptorStatus(kCCInvalidKey): self = .invalidKey
        default: self = .unspecified
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
            throw CCryptError(cryptorStatus: status)
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
