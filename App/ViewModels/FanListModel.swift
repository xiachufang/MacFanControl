import Foundation
import Observation
import FanDomain

@Observable
final class FanListModel {
    private(set) var fans: [Fan] = []
    private(set) var lastError: String?
    var headlineRPM: Int? { fans.map(\.currentRPM).max() }

    private let service: any FanService
    private var poller: PollingController?

    init(service: any FanService) {
        self.service = service
        self.poller = PollingController(service: service) { @MainActor [weak self] fans in
            self?.apply(fans: fans)
        }
        Task { await refreshOnce() }
    }

    func startPolling() {
        Task { await poller?.start() }
    }

    func stopPolling() {
        Task { await poller?.stop() }
    }

    func setMode(_ mode: FanMode, forFan index: Int) {
        Task {
            do {
                try await service.setMode(mode, forFan: index)
                await refreshOnce()
            } catch {
                lastError = String(describing: error)
            }
        }
    }

    private func apply(fans: [Fan]) {
        self.fans = fans
        self.lastError = nil
    }

    private func refreshOnce() async {
        do {
            let snapshot = try await service.snapshot()
            apply(fans: snapshot)
        } catch {
            lastError = String(describing: error)
        }
    }
}
