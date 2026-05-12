import Foundation
import FanDomain
import HelperIPC

/// Adapts the privileged XPC connection to `PrivilegedFanWriter`.
struct XPCFanWriter: PrivilegedFanWriter {
    let connection: AppXPCConnection

    func setForced(_ forced: Bool, fanIndex: Int) async throws {
        try await connection.setForced(forced, fanIndex: fanIndex)
    }

    func setTarget(rpm: Int, fanIndex: Int) async throws {
        try await connection.setTarget(rpm: rpm, fanIndex: fanIndex)
    }
}
