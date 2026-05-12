import Foundation
import IOKit

private let kSMCHandleYPCEvent: UInt32 = 2
private let kSMCReadKey: UInt8 = 5
private let kSMCWriteKey: UInt8 = 6
private let kSMCGetKeyInfo: UInt8 = 9

/// Layout of `SMCParamStruct` as expected by AppleSMC's user client. 80 bytes total.
/// Offsets account for arm64 C alignment: pLimitData (alignment 4) is padded to offset 12;
/// keyInfo.dataSize is at 28; result/status/data8 sit at 40/41/42 with 1 byte padding before
/// data32 at 44; the 32-byte payload starts at 48.
private struct SMCParam {
    var bytes: [UInt8] = Array(repeating: 0, count: 80)

    var key: UInt32 {
        get { read32(at: 0) }
        set { write32(newValue, at: 0) }
    }
    var keyInfoDataSize: UInt32 {
        get { read32(at: 28) }
        set { write32(newValue, at: 28) }
    }
    var keyInfoDataType: UInt32 {
        get { read32(at: 32) }
        set { write32(newValue, at: 32) }
    }
    var result: UInt8 {
        get { bytes[40] }
        set { bytes[40] = newValue }
    }
    var data8: UInt8 {
        get { bytes[42] }
        set { bytes[42] = newValue }
    }
    /// 32-byte payload at offset 48.
    var payload: ArraySlice<UInt8> {
        get { bytes[48..<80] }
        set {
            precondition(newValue.count <= 32)
            for (i, b) in newValue.enumerated() { bytes[48 + i] = b }
        }
    }

    /// Little-endian — the kernel reads these slots as native UInt32 on arm64/x86_64.
    /// The four-CC keys (e.g. `"FNum"` → 0x464E756D) match the literal `'FNum'` only when
    /// the bytes are stored in native order, not big-endian.
    private func read32(at offset: Int) -> UInt32 {
        UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }
    private mutating func write32(_ v: UInt32, at offset: Int) {
        bytes[offset]     = UInt8(v & 0xff)
        bytes[offset + 1] = UInt8((v >> 8) & 0xff)
        bytes[offset + 2] = UInt8((v >> 16) & 0xff)
        bytes[offset + 3] = UInt8((v >> 24) & 0xff)
    }
}

/// Real SMC backend that talks to the `AppleSMC` IOKit user client.
///
/// Thread-safety: every IOConnect call is serialized on `queue`. The connection handle is
/// not safe to share concurrently, but the wrapper hides that behind `Sendable` via the queue.
public final class IOKitSMCClient: SMCClient, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.slothease.macfancontrol.smc")
    private var connection: io_connect_t = 0

    public init() throws {
        let port: mach_port_t = kIOMainPortDefault
        // Apple Silicon exposes the SMC keys via `AppleSMCKeysEndpoint` (user client class
        // `AppleSMCClient`). Intel Macs match `AppleSMC` directly. Try the AS name first.
        let service: io_service_t = {
            let s = IOServiceGetMatchingService(port, IOServiceMatching("AppleSMCKeysEndpoint"))
            if s != 0 { return s }
            return IOServiceGetMatchingService(port, IOServiceMatching("AppleSMC"))
        }()
        guard service != 0 else { throw SMCError.openFailed(-1) }
        defer { IOObjectRelease(service) }

        var conn: io_connect_t = 0
        let kr = IOServiceOpen(service, mach_task_self_, 0, &conn)
        guard kr == KERN_SUCCESS else { throw SMCError.openFailed(kr) }
        self.connection = conn
    }

    deinit {
        if connection != 0 { IOServiceClose(connection) }
    }

    public func read(key: SMCKey) throws -> SMCValue {
        try queue.sync { try _read(key: key) }
    }

    public func write(key: SMCKey, value: SMCValue) throws {
        try queue.sync { try _write(key: key, value: value) }
    }

    // MARK: - private

    private func _read(key: SMCKey) throws -> SMCValue {
        // Step 1: ask for keyInfo (size + type).
        var info = SMCParam()
        info.key = key.fourCC
        info.data8 = kSMCGetKeyInfo
        let infoOut = try call(input: info)
        guard infoOut.result == 0 else {
            if infoOut.result == 0x84 { throw SMCError.keyNotFound(key) }
            throw SMCError.smcError(infoOut.result)
        }
        let dataSize = Int(infoOut.keyInfoDataSize)
        let dataType = infoOut.keyInfoDataType

        // Step 2: read the key now that we know its size/type.
        var read = SMCParam()
        read.key = key.fourCC
        read.data8 = kSMCReadKey
        read.keyInfoDataSize = UInt32(dataSize)
        read.keyInfoDataType = dataType
        let out = try call(input: read)
        guard out.result == 0 else {
            if out.result == 0x84 { throw SMCError.keyNotFound(key) }
            throw SMCError.smcError(out.result)
        }
        let payload = Data(out.payload.prefix(dataSize))
        return SMCValue(type: dataType, data: payload)
    }

    private func _write(key: SMCKey, value: SMCValue) throws {
        // Discover the expected size/type for the key first.
        var info = SMCParam()
        info.key = key.fourCC
        info.data8 = kSMCGetKeyInfo
        let infoOut = try call(input: info)
        guard infoOut.result == 0 else {
            if infoOut.result == 0x84 { throw SMCError.keyNotFound(key) }
            throw SMCError.smcError(infoOut.result)
        }

        // Re-encode if the caller gave us a different SMC type than the key actually uses.
        // Apple Silicon fan target keys are `flt`; Intel ones are `fpe2`. Same RPM, different bytes.
        let coerced = try value.reencoded(forType: infoOut.keyInfoDataType)

        var write = SMCParam()
        write.key = key.fourCC
        write.data8 = kSMCWriteKey
        write.keyInfoDataSize = infoOut.keyInfoDataSize
        write.keyInfoDataType = infoOut.keyInfoDataType
        let bytes = Array(coerced.data.prefix(Int(infoOut.keyInfoDataSize)))
        write.payload = ArraySlice(bytes)

        let out = try call(input: write)
        guard out.result == 0 else {
            if out.result == 0x85 { throw SMCError.notPermitted }
            throw SMCError.smcError(out.result)
        }
    }

    private func call(input: SMCParam) throws -> SMCParam {
        var inBytes = input.bytes
        var outBytes = [UInt8](repeating: 0, count: 80)
        var outSize = 80

        let kr = inBytes.withUnsafeMutableBytes { inBuf -> kern_return_t in
            outBytes.withUnsafeMutableBytes { outBuf in
                IOConnectCallStructMethod(
                    connection,
                    kSMCHandleYPCEvent,
                    inBuf.baseAddress,
                    80,
                    outBuf.baseAddress,
                    &outSize
                )
            }
        }
        guard kr == KERN_SUCCESS else { throw SMCError.ioKitError(kr) }
        var result = SMCParam()
        result.bytes = outBytes
        return result
    }
}
