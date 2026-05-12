import Foundation

/// Wire protocol exposed by the privileged helper. `@objc` because NSXPCConnection
/// requires Objective-C runtime visibility for the proxy interface.
@objc public protocol FanHelperXPC {
    func setFanForced(_ forced: Bool,
                      index: Int,
                      reply: @Sendable @escaping (NSError?) -> Void)
    func setFanTarget(rpm: Int,
                      index: Int,
                      reply: @Sendable @escaping (NSError?) -> Void)
    func ping(reply: @Sendable @escaping (String) -> Void)
}

public enum HelperConstants {
    public static let helperBundleID  = "com.slothease.macfancontrol.helper"
    public static let machServiceName = "com.slothease.macfancontrol.helper"
    public static let daemonPlistName = "com.slothease.macfancontrol.helper.plist"
    /// Bumped on protocol changes — used by the app's `ping` handshake to detect stale daemons.
    public static let protocolVersion = "1"
}
