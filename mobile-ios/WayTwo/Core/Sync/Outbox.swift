import Foundation

final class Outbox {
    enum Operation: String {
        case patchProfile = "PATCH_PROFILE"
        case uploadAvatar = "UPLOAD_AVATAR"
        case completeOnboarding = "COMPLETE_ONBOARDING"
    }

    private let database: DatabaseClient
    private let apiClient: APIClient
    private let tokenSource: TokenSource
    private let logger: AppLogger

    init(database: DatabaseClient, apiClient: APIClient, tokenSource: TokenSource, logger: AppLogger) {
        self.database = database
        self.apiClient = apiClient
        self.tokenSource = tokenSource
        self.logger = logger
    }

    func enqueue(operation: Operation, entityId: String, payload: [String: String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let serialized = String(data: data, encoding: .utf8)
        else { return }
        database.enqueueOutbox(operation: operation.rawValue, entityId: entityId, payload: serialized)
    }

    func flush() async {
        let items = database.fetchOutbox()
        guard !items.isEmpty else { return }

        // No point retrying items one by one against a dead session.
        guard (try? await tokenSource.currentAccessToken()) != nil else {
            logger.info("outbox.flush", metadata: ["op": "skip", "reason": "no_token"])
            return
        }

        logger.info("outbox.flush", metadata: ["op": "start", "count": "\(items.count)"])
        for item in items {
            let payload = parsePayload(item.payload)
            do {
                if item.operation == Operation.patchProfile.rawValue {
                    let remote = try await apiClient.patchProfile(tokenSource: tokenSource, body: payload)
                    database.applyRemoteProfile(remote)
                } else if item.operation == Operation.uploadAvatar.rawValue {
                    if let local = payload["photo_local_uri"] {
                        let remote = try await apiClient.patchProfile(tokenSource: tokenSource, body: ["photo_path": local])
                        database.applyRemoteProfile(remote)
                    }
                } else if item.operation == Operation.completeOnboarding.rawValue {
                    let remote = try await apiClient.postProfileComplete(tokenSource: tokenSource)
                    database.applyRemoteProfile(remote)
                }
                database.deleteOutbox(id: item.id)
            } catch {
                logger.warn("outbox.flush", metadata: ["status": "failed", "operation": item.operation])
                database.incrementOutboxAttempts(id: item.id, message: "request_failed")
                continue
            }
        }
        logger.info("outbox.flush", metadata: ["op": "done"])
    }

    private func parsePayload(_ payload: String) -> [String: String] {
        guard let data = payload.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else {
            return [:]
        }
        return dict
    }
}
