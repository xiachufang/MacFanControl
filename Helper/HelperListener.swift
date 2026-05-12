import Foundation
import HelperIPC
import Security

/// Validates incoming XPC connections against the parent app's signing identity (Team ID +
/// bundle ID) before exposing the fan-writer interface. Rejecting unknown clients is the
/// primary defence — a privileged daemon must never trust whoever happens to dial in.
/// `nonisolated` because XPC invokes delegate methods on its own dispatch queue, not the
/// main actor. Without this, Approachable Concurrency would infer `@MainActor` for the
/// class and the runtime would trap on the first incoming connection.
nonisolated final class HelperListener: NSObject, NSXPCListenerDelegate {
    private let allowedClientBundleID = "com.allsunday.macfancontrol"
    /// The Team ID this helper itself is signed by — derived from our own SecCode at startup
    /// rather than hardcoded. Whoever signs the helper transitively dictates which apps may
    /// connect: the same identity must sign the calling app. `nil` for ad-hoc builds (then
    /// only the bundle identifier is checked).
    private let requiredTeamIDOrNil: String? = HelperListener.ownTeamID()

    private static func ownTeamID() -> String? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code as! SecStaticCode, [], &info) == errSecSuccess,
              let dict = info as? [String: Any] else { return nil }
        return dict[kSecCodeInfoTeamIdentifier as String] as? String
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        guard validateClient(connection) else {
            NSLog("[MacFanControlHelper] rejecting unverified client pid=%d", connection.processIdentifier)
            return false
        }

        connection.exportedInterface = NSXPCInterface(with: FanHelperXPC.self)
        let writer = FanWriterImpl()
        connection.exportedObject = writer
        connection.invalidationHandler = { [weak writer] in _ = writer }
        connection.resume()
        return true
    }

    private func validateClient(_ connection: NSXPCConnection) -> Bool {
        var token = connection.auditToken
        let attrs = [
            kSecGuestAttributeAudit: Data(bytes: &token, count: MemoryLayout.size(ofValue: token))
        ] as CFDictionary

        var codeRef: SecCode?
        let copyStatus = SecCodeCopyGuestWithAttributes(nil, attrs, [], &codeRef)
        guard copyStatus == errSecSuccess, let code = codeRef else { return false }

        let requirementText: String
        if let team = requiredTeamIDOrNil {
            requirementText = """
            anchor apple generic and identifier "\(allowedClientBundleID)" \
            and certificate leaf[subject.OU] = "\(team)"
            """
        } else {
            requirementText = #"identifier "\#(allowedClientBundleID)""#
        }

        var requirement: SecRequirement?
        guard SecRequirementCreateWithString(requirementText as CFString, [], &requirement) == errSecSuccess,
              let req = requirement else { return false }

        let validateStatus = SecCodeCheckValidity(code, [], req)
        return validateStatus == errSecSuccess
    }
}

private extension NSXPCConnection {
    /// `auditToken` is a 32-byte struct, so `performSelector` mis-handles its return value
    /// and crashes (KERN_PROTECTION_FAILURE) — KVC via `value(forKey:)` boxes it as NSValue.
    nonisolated var auditToken: audit_token_t {
        var token = audit_token_t()
        if let value = self.value(forKey: "auditToken") as? NSValue {
            value.getValue(&token, size: MemoryLayout<audit_token_t>.size)
        }
        return token
    }
}
