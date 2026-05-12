import Foundation

public struct SMCKey: Hashable, Sendable, CustomStringConvertible {
    public let fourCC: UInt32
    public init(fourCC: UInt32) { self.fourCC = fourCC }
    public init(_ ascii: String) {
        precondition(ascii.utf8.count == 4, "SMC key must be exactly 4 ASCII bytes")
        var v: UInt32 = 0
        for byte in ascii.utf8 { v = (v << 8) | UInt32(byte) }
        self.fourCC = v
    }
    public var description: String {
        let bytes = [UInt8((fourCC >> 24) & 0xff), UInt8((fourCC >> 16) & 0xff),
                     UInt8((fourCC >> 8) & 0xff), UInt8(fourCC & 0xff)]
        return String(bytes: bytes, encoding: .ascii) ?? "0x\(String(fourCC, radix: 16))"
    }
}

public struct SMCValue: Sendable, Equatable {
    public let type: UInt32
    public let data: Data
    public init(type: UInt32, data: Data) { self.type = type; self.data = data }
    public init(typeFourCC: String, data: Data) {
        precondition(typeFourCC.utf8.count == 4, "type must be 4 ASCII bytes")
        var v: UInt32 = 0
        for byte in typeFourCC.utf8 { v = (v << 8) | UInt32(byte) }
        self.type = v
        self.data = data
    }
}

public enum SMCError: Error, Equatable, Sendable {
    case notPermitted
    case keyNotFound(SMCKey)
    case openFailed(Int32)
    case ioKitError(Int32)
    case smcError(UInt8)
    case decodeFailed(reason: String)
}

public enum SMCType {
    public static let fpe2: UInt32 = 0x66706532   // "fpe2"
    public static let ui8:  UInt32 = 0x75693820   // "ui8 "
    public static let ui16: UInt32 = 0x75693136   // "ui16"
    public static let ui32: UInt32 = 0x75693332   // "ui32"
    public static let flt:  UInt32 = 0x666c7420   // "flt "
    public static let flag: UInt32 = 0x666c6167   // "flag"
}
