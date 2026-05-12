import Foundation
import SMCKit

public struct DefaultFanService: FanService {
    private let reader: any SMCClient
    private let writer: any PrivilegedFanWriter

    public init(reader: any SMCClient, writer: any PrivilegedFanWriter) {
        self.reader = reader
        self.writer = writer
    }

    public func snapshot() async throws -> [Fan] {
        let countValue = try reader.read(key: FanKeys.count)
        let count = Int(try countValue.decodeAsDouble())
        guard count > 0 else { return [] }

        var fans: [Fan] = []
        fans.reserveCapacity(count)
        for i in 0..<count {
            let minR = Int(try reader.read(key: FanKeys.minRPM(i)).decodeAsDouble())
            let maxR = Int(try reader.read(key: FanKeys.maxRPM(i)).decodeAsDouble())
            let cur  = Int(try reader.read(key: FanKeys.actual(i)).decodeAsDouble())
            let modeRaw = Int(try reader.read(key: FanKeys.mode(i)).decodeAsDouble())
            let target = Int(try reader.read(key: FanKeys.target(i)).decodeAsDouble())
            let mode = derivedMode(modeRaw: modeRaw, target: target, min: minR, max: maxR)
            fans.append(Fan(index: i, minRPM: minR, maxRPM: maxR, currentRPM: cur, mode: mode))
        }
        return fans
    }

    public func setMode(_ mode: FanMode, forFan index: Int) async throws {
        switch mode {
        case .auto:
            try await writer.setForced(false, fanIndex: index)
        case .silent, .balanced, .full:
            let minR = Int(try reader.read(key: FanKeys.minRPM(index)).decodeAsDouble())
            let maxR = Int(try reader.read(key: FanKeys.maxRPM(index)).decodeAsDouble())
            let target = mode.targetRPM(min: minR, max: maxR)
            try await writer.setForced(true, fanIndex: index)
            try await writer.setTarget(rpm: target, fanIndex: index)
        }
    }

    private func derivedMode(modeRaw: Int, target: Int, min: Int, max: Int) -> FanMode {
        guard modeRaw != 0 else { return .auto }
        let silent = min
        let balanced = (min + max) / 2
        let full = max
        let candidates: [(FanMode, Int)] = [(.silent, silent), (.balanced, balanced), (.full, full)]
        let nearest = candidates.min { abs($0.1 - target) < abs($1.1 - target) }
        return nearest?.0 ?? .full
    }
}
