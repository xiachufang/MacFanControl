import Testing
import Foundation
@testable import FanDomain
@testable import SMCKit

private final class RecordingWriter: PrivilegedFanWriter, @unchecked Sendable {
    var setForcedCalls: [(Bool, Int)] = []
    var setTargetCalls: [(Int, Int)] = []
    func setForced(_ forced: Bool, fanIndex: Int) async throws {
        setForcedCalls.append((forced, fanIndex))
    }
    func setTarget(rpm: Int, fanIndex: Int) async throws {
        setTargetCalls.append((rpm, fanIndex))
    }
}

@Test func snapshot_returns_two_fans_from_default_seed() async throws {
    let service = DefaultFanService(reader: MockSMCClient(), writer: RecordingWriter())
    let fans = try await service.snapshot()
    #expect(fans.count == 2)
    #expect(fans[0].minRPM == 1200)
    #expect(fans[0].maxRPM == 5500)
    #expect(fans[0].mode == .auto)
}

@Test func setMode_full_writes_forced_and_max_rpm() async throws {
    let writer = RecordingWriter()
    let service = DefaultFanService(reader: MockSMCClient(), writer: writer)
    try await service.setMode(.full, forFan: 0)
    #expect(writer.setForcedCalls.first?.0 == true)
    #expect(writer.setForcedCalls.first?.1 == 0)
    #expect(writer.setTargetCalls.first?.0 == 5500)
    #expect(writer.setTargetCalls.first?.1 == 0)
}

@Test func setMode_silent_writes_min_rpm() async throws {
    let writer = RecordingWriter()
    let service = DefaultFanService(reader: MockSMCClient(), writer: writer)
    try await service.setMode(.silent, forFan: 1)
    #expect(writer.setTargetCalls.first?.0 == 800)
    #expect(writer.setTargetCalls.first?.1 == 1)
}

@Test func setMode_balanced_writes_midpoint() async throws {
    let writer = RecordingWriter()
    let service = DefaultFanService(reader: MockSMCClient(), writer: writer)
    try await service.setMode(.balanced, forFan: 0)
    #expect(writer.setTargetCalls.first?.0 == (1200 + 5500) / 2)
}

@Test func setMode_auto_clears_forced_no_target_write() async throws {
    let writer = RecordingWriter()
    let service = DefaultFanService(reader: MockSMCClient(), writer: writer)
    try await service.setMode(.auto, forFan: 0)
    #expect(writer.setForcedCalls.first?.0 == false)
    #expect(writer.setTargetCalls.isEmpty)
}
