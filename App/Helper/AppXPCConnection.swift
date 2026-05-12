import Foundation
import HelperIPC

/// Owns the single privileged Mach-service connection. Calls happen inside the actor so the
/// non-Sendable proxy never crosses an isolation boundary.
actor AppXPCConnection {
    private var connection: NSXPCConnection?

    func setForced(_ forced: Bool, fanIndex: Int) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let proxy = ensureProxyWithErrorHandler { cont.resume(throwing: $0) }
            proxy.setFanForced(forced, index: fanIndex) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    func setTarget(rpm: Int, fanIndex: Int) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let proxy = ensureProxyWithErrorHandler { cont.resume(throwing: $0) }
            proxy.setFanTarget(rpm: rpm, index: fanIndex) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
    }

    func ping() async throws -> String {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            let proxy = ensureProxyWithErrorHandler { cont.resume(throwing: $0) }
            proxy.ping { version in cont.resume(returning: version) }
        }
    }

    func tearDown() {
        connection?.invalidate()
        connection = nil
    }

    private func ensureProxyWithErrorHandler(_ onError: @Sendable @escaping (Error) -> Void) -> any FanHelperXPC {
        let conn = connection ?? makeConnection()
        connection = conn
        let proxy = conn.remoteObjectProxyWithErrorHandler { [weak self] error in
            Task { await self?.clear() }
            onError(error)
        }
        return proxy as! any FanHelperXPC
    }

    private func makeConnection() -> NSXPCConnection {
        let conn = NSXPCConnection(
            machServiceName: HelperConstants.machServiceName,
            options: .privileged
        )
        conn.remoteObjectInterface = NSXPCInterface(with: FanHelperXPC.self)
        conn.invalidationHandler = { [weak self] in
            Task { await self?.clear() }
        }
        conn.interruptionHandler = { [weak self] in
            Task { await self?.clear() }
        }
        conn.resume()
        return conn
    }

    private func clear() {
        connection = nil
    }
}
