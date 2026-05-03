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

        let token = keychain.loadSession()?.accessToken
        logger.info("sync.coordinator", metadata: [
            "op": "flush",
            "hasToken": token != nil ? "yes" : "no"
        ])
        await outbox.flush(accessToken: token)
        if let token {
            await profileSync.pullProfile(accessToken: token)
        }
        logger.info("sync.coordinator", metadata: ["op": "flush_done"])
    }

    func appBecameForeground() {
        Task { await sessionBecameActive() }
    }
}
