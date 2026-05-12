import Foundation

/// Protocol for any SMC backend. `nonisolated` so callers on any actor can use it.
public protocol SMCClient: Sendable {
    nonisolated func read(key: SMCKey) throws -> SMCValue
    nonisolated func write(key: SMCKey, value: SMCValue) throws
}
