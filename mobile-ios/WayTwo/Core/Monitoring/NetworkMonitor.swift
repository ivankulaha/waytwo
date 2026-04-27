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

    init(logger: AppLogger) {
        self.logger = logger
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.status = path.status == .satisfied ? .online : .offline
            self.logger.debug("network.status", metadata: ["value": self.status == .online ? "online" : "offline"])
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
