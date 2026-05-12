import Foundation

public protocol FanService: Sendable {
    nonisolated func snapshot() async throws -> [Fan]
    nonisolated func setMode(_ mode: FanMode, forFan index: Int) async throws
}

public protocol PrivilegedFanWriter: Sendable {
    nonisolated func setForced(_ forced: Bool, fanIndex: Int) async throws
    nonisolated func setTarget(rpm: Int, fanIndex: Int) async throws
}

/// No-op writer used in previews / dev mode where no helper is installed yet.
public struct NoopFanWriter: PrivilegedFanWriter {
    public init() {}
    public func setForced(_ forced: Bool, fanIndex: Int) async throws {}
    public func setTarget(rpm: Int, fanIndex: Int) async throws {}
}
