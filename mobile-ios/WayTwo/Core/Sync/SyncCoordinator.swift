import Foundation

final class SyncCoordinator {
    private let profileSync: ProfileSync
    private let keychain: KeychainClient
    private let networkMonitor: NetworkMonitor
    private let logger: AppLogger
    private let pullLock = NSLock()
    private var pullInProgress = false

    init(
        profileSync: ProfileSync,
        keychain: KeychainClient,
        networkMonitor: NetworkMonitor,
        logger: AppLogger
    ) {
        self.profileSync = profileSync
        self.keychain = keychain
        self.networkMonitor = networkMonitor
        self.logger = logger

        networkMonitor.onBecameOnline = { [weak self] in
            Task { await self?.sessionBecameActive() }
        }
    }

    func sessionBecameActive() async {
        pullLock.lock()
        if pullInProgress {
            pullLock.unlock()
            return
        }
        pullInProgress = true
        pullLock.unlock()
        defer {
            pullLock.lock()
            pullInProgress = false
            pullLock.unlock()
        }

        guard keychain.loadSession() != nil else {
            logger.info("sync.coordinator", metadata: ["op": "skip", "reason": "no_session"])
            return
        }
        logger.info("sync.coordinator", metadata: ["op": "pull"])
        await profileSync.pullProfile()
        logger.info("sync.coordinator", metadata: ["op": "pull_done"])
    }

    func appBecameForeground() {
        Task { await sessionBecameActive() }
    }
}
