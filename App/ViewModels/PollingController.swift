import Foundation
import FanDomain

/// Drives a periodic snapshot loop while the menu is open. Lives off the main actor so
/// the polling cadence is unaffected by UI work.
actor PollingController {
    private let service: any FanService
    private let onSnapshot: @MainActor @Sendable ([Fan]) -> Void
    private let interval: Duration
    private var task: Task<Void, Never>?

    init(service: any FanService,
         interval: Duration = .milliseconds(1500),
         onSnapshot: @escaping @MainActor @Sendable ([Fan]) -> Void) {
        self.service = service
        self.interval = interval
        self.onSnapshot = onSnapshot
    }

    func start() {
        guard task == nil else { return }
        task = Task { [service, interval, onSnapshot] in
            while !Task.isCancelled {
                if let fans = try? await service.snapshot() {
                    await onSnapshot(fans)
                }
                try? await Task.sleep(for: interval)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
