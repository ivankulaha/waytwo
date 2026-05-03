import Foundation
import Network

final class NetworkMonitor {
    enum Status {
        case online
        case offline
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "waytwo.network.monitor")
    private let logger: AppLogger

    private(set) var status: Status = .offline
    var onBecameOnline: (() -> Void)?

    init(logger: AppLogger) {
        self.logger = logger
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let newStatus: Status = path.status == .satisfied ? .online : .offline
            let previous = self.status
            if newStatus == .online && previous == .offline {
                self.onBecameOnline?()
            }
            self.status = newStatus
            self.logger.debug("network.status", metadata: ["value": self.status == .online ? "online" : "offline"])
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
