import Foundation

final class ProfileSync {
    private let database: DatabaseClient
    private let apiClient: APIClient
    private let tokenSource: TokenSource
    private let outbox: Outbox
    private let logger: AppLogger

    init(database: DatabaseClient, apiClient: APIClient, tokenSource: TokenSource, outbox: Outbox, logger: AppLogger) {
        self.database = database
        self.apiClient = apiClient
        self.tokenSource = tokenSource
        self.outbox = outbox
        self.logger = logger
    }

    func pullProfile() async {
        do {
            let remote = try await apiClient.fetchProfile(tokenSource: tokenSource)
            database.applyRemoteProfile(remote)
        } catch {
            logger.warn("sync.pull", metadata: ["status": "failed"])
        }
    }

    func pushProfile(patch: ProfilePatch) {
        logger.info("sync.pushProfile", metadata: ["op": "enqueue"])
        database.upsertProfileFields(patch)
        outbox.enqueue(operation: .patchProfile, entityId: "profile", payload: patch.asDictionary())
    }

    func pushAvatar(localURI: String) {
        logger.info("sync.pushAvatar", metadata: ["op": "enqueue"])
        outbox.enqueue(operation: .uploadAvatar, entityId: "avatar", payload: ["photo_local_uri": localURI])
    }

    func enqueueCompleteOnboarding() {
        logger.info("sync.completeOnboarding", metadata: ["op": "enqueue"])
        outbox.enqueue(operation: .completeOnboarding, entityId: "onboarding", payload: [:])
    }
}
