import Foundation

public extension SMCValue {
    /// Decode common numeric SMC types into a `Double`. Throws `decodeFailed` on unknown types.
    func decodeAsDouble() throws -> Double {
        switch type {
        case SMCType.fpe2:
            guard data.count >= 2 else { throw SMCError.decodeFailed(reason: "fpe2 needs 2 bytes") }
            let raw = (UInt16(data[0]) << 8) | UInt16(data[1])
            return Double(raw) / 4.0
        case SMCType.ui8:
            guard data.count >= 1 else { throw SMCError.decodeFailed(reason: "ui8 needs 1 byte") }
            return Double(data[0])
        case SMCType.ui16:
            guard data.count >= 2 else { throw SMCError.decodeFailed(reason: "ui16 needs 2 bytes") }
            let v = (UInt16(data[0]) << 8) | UInt16(data[1])
            return Double(v)
        case SMCType.ui32:
            guard data.count >= 4 else { throw SMCError.decodeFailed(reason: "ui32 needs 4 bytes") }
            var v: UInt32 = 0
            for byte in data.prefix(4) { v = (v << 8) | UInt32(byte) }
            return Double(v)
        case SMCType.flt:
            guard data.count >= 4 else { throw SMCError.decodeFailed(reason: "flt needs 4 bytes") }
            let le = Data(data.prefix(4))
            let f: Float = le.withUnsafeBytes { $0.load(as: Float.self) }
            return Double(f)
        case SMCType.flag:
            guard data.count >= 1 else { throw SMCError.decodeFailed(reason: "flag needs 1 byte") }
            return data[0] == 0 ? 0 : 1
        default:
            throw SMCError.decodeFailed(reason: "unknown SMC type \(String(type, radix: 16))")
        }
    }

    static func encodeFPE2(_ rpm: Int) -> SMCValue {
        let clamped = max(0, min(rpm, 65535 / 4 * 4)) * 4 / 4
        let raw = UInt16(clamped * 4)
        let bytes: [UInt8] = [UInt8(raw >> 8), UInt8(raw & 0xff)]
        return SMCValue(type: SMCType.fpe2, data: Data(bytes))
    }

    static func encodeUI8(_ value: UInt8) -> SMCValue {
        SMCValue(type: SMCType.ui8, data: Data([value]))
    }

    /// Little-endian IEEE-754 float, as used by Apple Silicon SMC for fan keys.
    static func encodeFlt(_ value: Float) -> SMCValue {
        var v = value
        let bytes = withUnsafeBytes(of: &v) { Array($0) }
        return SMCValue(type: SMCType.flt, data: Data(bytes))
    }

    /// Re-encode the value so its bytes match the wire format the SMC expects for `targetType`.
    /// This is what makes the same `Int` rpm work whether the kernel reports the key as
    /// `fpe2` (Intel) or `flt ` (Apple Silicon) — the caller just hands us a number.
    func reencoded(forType targetType: UInt32) throws -> SMCValue {
        if type == targetType { return self }
        let logicalValue = try decodeAsDouble()
        switch targetType {
        case SMCType.flt:  return .encodeFlt(Float(logicalValue))
        case SMCType.fpe2: return .encodeFPE2(Int(logicalValue))
        case SMCType.ui8:  return .encodeUI8(UInt8(clamping: Int(logicalValue)))
        default:
            throw SMCError.decodeFailed(reason: "no encoder for type \(String(targetType, radix: 16))")
        }
    }
}
