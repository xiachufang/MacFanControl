import Foundation
import Observation
import ServiceManagement
import HelperIPC

@Observable
final class HelperInstaller {
    enum Health: Equatable {
        case unknown
        case notInstalled
        case requiresApproval
        case healthy(version: String)
        case unreachable(String)
        case failed(String)
    }

    private(set) var health: Health = .unknown

    private let service = SMAppService.daemon(plistName: HelperConstants.daemonPlistName)
    private let pinger: @Sendable () async throws -> String

    init(pinger: @escaping @Sendable () async throws -> String) {
        self.pinger = pinger
    }

    func refresh() async {
        switch service.status {
        case .notRegistered, .notFound:
            health = .notInstalled
        case .requiresApproval:
            health = .requiresApproval
        case .enabled:
            do {
                let version = try await pinger()
                health = .healthy(version: version)
            } catch {
                health = .unreachable(error.localizedDescription)
            }
        @unknown default:
            health = .unknown
        }
    }

    func install() {
        try? service.unregister()
        do {
            try service.register()
        } catch {
            health = .failed(error.localizedDescription)
            return
        }
        Task { await refresh() }
    }

    /// Same as install — explicit name for the "registered but unreachable" recovery flow.
    func reinstall() { install() }

    func uninstall() {
        do {
            try service.unregister()
            health = .notInstalled
        } catch {
            health = .failed(error.localizedDescription)
        }
    }

    func openLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
