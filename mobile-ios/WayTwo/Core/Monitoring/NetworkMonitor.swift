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
    var onStatusChange: ((Status) -> Void)?

    init(logger: AppLogger) {
        self.logger = logger
        monitor.pathUpdateHandler = { [weak self] path in
            let newStatus: Status = path.status == .satisfied ? .online : .offline
            DispatchQueue.main.async {
                guard let self else { return }
                let previous = self.status
                self.status = newStatus
                if newStatus != previous {
                    self.onStatusChange?(newStatus)
                }
                if newStatus == .online && previous == .offline {
                    self.onBecameOnline?()
                }
                self.logger.debug("network.status", metadata: ["value": self.status == .online ? "online" : "offline"])
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
