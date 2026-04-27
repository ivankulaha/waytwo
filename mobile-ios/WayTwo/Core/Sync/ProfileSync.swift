import Foundation

final class ProfileSync {
    private let database: DatabaseClient
    private let apiClient: APIClient
    private let outbox: Outbox
    private let logger: AppLogger

    init(database: DatabaseClient, apiClient: APIClient, outbox: Outbox, logger: AppLogger) {
        self.database = database
        self.apiClient = apiClient
        self.outbox = outbox
        self.logger = logger
    }

    func pullProfile(accessToken: String) async {
        do {
            let remote = try await apiClient.fetchProfile(accessToken: accessToken)
            database.applyRemoteProfile(remote)
        } catch {
            logger.warn("sync.pull", metadata: ["status": "failed"])
        }
    }

    func pushProfile(partial: [String: String], accessToken: String?) async {
        database.upsertProfileFields(partial)
        outbox.enqueue(operation: .patchProfile, entityId: "profile", payload: partial)
        await outbox.flush(accessToken: accessToken)
    }

    func pushAvatar(localURI: String, accessToken: String?) async {
        outbox.enqueue(operation: .uploadAvatar, entityId: "avatar", payload: ["photo_local_uri": localURI])
        await outbox.flush(accessToken: accessToken)
    }

    func pushCompleteOnboarding(accessToken: String?) async {
        outbox.enqueue(operation: .completeOnboarding, entityId: "onboarding", payload: [:])
        await outbox.flush(accessToken: accessToken)
        if let accessToken {
            await pullProfile(accessToken: accessToken)
        }
    }
}
