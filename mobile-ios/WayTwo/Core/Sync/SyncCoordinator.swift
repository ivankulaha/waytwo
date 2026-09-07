import Foundation

final class SyncCoordinator {
    private let outbox: Outbox
    private let profileSync: ProfileSync
    private let keychain: KeychainClient
    private let networkMonitor: NetworkMonitor
    private let logger: AppLogger
    private let flushLock = NSLock()
    private var flushInProgress = false

    init(
        outbox: Outbox,
        profileSync: ProfileSync,
        keychain: KeychainClient,
        networkMonitor: NetworkMonitor,
        logger: AppLogger
    ) {
        self.outbox = outbox
        self.profileSync = profileSync
        self.keychain = keychain
        self.networkMonitor = networkMonitor
        self.logger = logger

        networkMonitor.onBecameOnline = { [weak self] in
            Task { await self?.sessionBecameActive() }
        }
    }

    func sessionBecameActive() async {
        flushLock.lock()
        if flushInProgress {
            flushLock.unlock()
            return
        }
        flushInProgress = true
        flushLock.unlock()
        defer {
            flushLock.lock()
            flushInProgress = false
            flushLock.unlock()
        }

        guard keychain.loadSession() != nil else {
            logger.info("sync.coordinator", metadata: ["op": "skip", "reason": "no_session"])
            return
        }
        logger.info("sync.coordinator", metadata: ["op": "flush"])
        await outbox.flush()
        await profileSync.pullProfile()
        logger.info("sync.coordinator", metadata: ["op": "flush_done"])
    }

    func appBecameForeground() {
        Task { await sessionBecameActive() }
    }
}
