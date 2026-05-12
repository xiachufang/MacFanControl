import Foundation
import HelperIPC
import SMCKit

/// SMC writer running as root inside the helper. Owns a single IOKit connection.
/// `nonisolated` for the same reason as `HelperListener` — XPC reply handlers fire on
/// dispatch queues, not on the main actor.
nonisolated final class FanWriterImpl: NSObject, FanHelperXPC {
    private let smc: SMCClient

    override init() {
        do {
            self.smc = try IOKitSMCClient()
        } catch {
            NSLog("[MacFanControlHelper] failed to open AppleSMC: %@", String(describing: error))
            // Crash the daemon; launchd will respawn on next XPC connect.
            fatalError("AppleSMC unavailable")
        }
        super.init()
    }

    func setFanForced(_ forced: Bool, index: Int, reply: @Sendable @escaping (NSError?) -> Void) {
        do {
            let key = SMCKey("F\(index)Md")
            try smc.write(key: key, value: .encodeUI8(forced ? 1 : 0))
            reply(nil)
        } catch {
            reply(NSError(domain: "MacFanControlHelper", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: String(describing: error)]))
        }
    }

    func setFanTarget(rpm: Int, index: Int, reply: @Sendable @escaping (NSError?) -> Void) {
        do {
            let key = SMCKey("F\(index)Tg")
            try smc.write(key: key, value: .encodeFPE2(rpm))
            reply(nil)
        } catch {
            reply(NSError(domain: "MacFanControlHelper", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: String(describing: error)]))
        }
    }

    func ping(reply: @Sendable @escaping (String) -> Void) {
        reply(HelperConstants.protocolVersion)
    }
}
