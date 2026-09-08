import Foundation

enum ProfileSyncError: Error, Equatable {
    case saveFailed

    var localizationKey: String { "error.saveFailed" }
}

final class ProfileSync {
    private let database: DatabaseClient
    private let apiClient: APIClient
    private let tokenSource: TokenSource
    private let logger: AppLogger

    init(
        database: DatabaseClient,
        apiClient: APIClient,
        tokenSource: TokenSource,
        logger: AppLogger
    ) {
        self.database = database
        self.apiClient = apiClient
        self.tokenSource = tokenSource
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

    func pushProfile(patch: ProfilePatch) async -> Result<Void, ProfileSyncError> {
        logger.info("sync.pushProfile", metadata: ["op": "start"])
        do {
            let remote = try await apiClient.patchProfile(tokenSource: tokenSource, body: patch.asDictionary())
            database.applyRemoteProfile(remote)
            logger.info("sync.pushProfile", metadata: ["op": "done", "status": "ok"])
            return .success(())
        } catch {
            logger.error("sync.pushProfile", metadata: ["op": "done", "status": "failed"])
            return .failure(.saveFailed)
        }
    }

    func completeOnboarding(look: ProfilePatch) async -> Result<Void, ProfileSyncError> {
        logger.info("sync.completeOnboarding", metadata: ["op": "start"])
        do {
            let lookBody = look.asDictionary()
            if !lookBody.isEmpty {
                _ = try await apiClient.patchProfile(tokenSource: tokenSource, body: lookBody)
            }
            let remote = try await apiClient.postProfileComplete(tokenSource: tokenSource)
            database.applyRemoteProfile(remote)
            database.markOnboardingCompleted()
            logger.info("sync.completeOnboarding", metadata: ["op": "done", "status": "ok"])
            return .success(())
        } catch {
            logger.error("sync.completeOnboarding", metadata: ["op": "done", "status": "failed"])
            return .failure(.saveFailed)
        }
    }
}
