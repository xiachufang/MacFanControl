import Foundation

/// In-memory mock SMC backend. Used by previews, tests, and dev builds without a real
/// privileged helper installed. Seed it with whatever fan layout you want to simulate.
public final class MockSMCClient: SMCClient, @unchecked Sendable {
    private let lock = NSLock()
    private var store: [SMCKey: SMCValue] = [:]
    public private(set) var writes: [(key: SMCKey, value: SMCValue)] = []

    public init(seed: [SMCKey: SMCValue] = MockSMCClient.defaultFanSeed()) {
        self.store = seed
    }

    public func read(key: SMCKey) throws -> SMCValue {
        lock.lock(); defer { lock.unlock() }
        guard let v = store[key] else { throw SMCError.keyNotFound(key) }
        return v
    }

    public func write(key: SMCKey, value: SMCValue) throws {
        lock.lock(); defer { lock.unlock() }
        store[key] = value
        writes.append((key, value))
    }

    /// Convenient seed: 2 fans (1200..5500 RPM and 800..4500 RPM), both auto, idling.
    public static func defaultFanSeed() -> [SMCKey: SMCValue] {
        var seed: [SMCKey: SMCValue] = [:]
        seed[SMCKey("FNum")] = .encodeUI8(2)

        seed[SMCKey("F0Mn")] = .encodeFPE2(1200)
        seed[SMCKey("F0Mx")] = .encodeFPE2(5500)
        seed[SMCKey("F0Ac")] = .encodeFPE2(2400)
        seed[SMCKey("F0Md")] = .encodeUI8(0)
        seed[SMCKey("F0Tg")] = .encodeFPE2(0)

        seed[SMCKey("F1Mn")] = .encodeFPE2(800)
        seed[SMCKey("F1Mx")] = .encodeFPE2(4500)
        seed[SMCKey("F1Ac")] = .encodeFPE2(1500)
        seed[SMCKey("F1Md")] = .encodeUI8(0)
        seed[SMCKey("F1Tg")] = .encodeFPE2(0)
        return seed
    }
}
