import Foundation

public struct Fan: Identifiable, Sendable, Equatable {
    public let index: Int
    public let minRPM: Int
    public let maxRPM: Int
    public let currentRPM: Int
    public let mode: FanMode

    public var id: Int { index }
    public var displayName: String { "Fan \(index + 1)" }

    public init(index: Int, minRPM: Int, maxRPM: Int, currentRPM: Int, mode: FanMode) {
        self.index = index
        self.minRPM = minRPM
        self.maxRPM = maxRPM
        self.currentRPM = currentRPM
        self.mode = mode
    }
}

public enum FanMode: Sendable, Equatable, Hashable, CaseIterable {
    case auto, silent, balanced, full

    public var displayName: String {
        switch self {
        case .auto:     return "Auto"
        case .silent:   return "Silent"
        case .balanced: return "Balanced"
        case .full:     return "Full"
        }
    }

    /// Resolve the target RPM for non-auto modes given a fan's range.
    public func targetRPM(min: Int, max: Int) -> Int {
        switch self {
        case .auto:     return 0
        case .silent:   return min
        case .balanced: return (min + max) / 2
        case .full:     return max
        }
    }
}
