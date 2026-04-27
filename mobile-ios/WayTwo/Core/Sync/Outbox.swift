import Foundation

final class Outbox {
    enum Operation: String {
        case patchProfile = "PATCH_PROFILE"
        case uploadAvatar = "UPLOAD_AVATAR"
        case completeOnboarding = "COMPLETE_ONBOARDING"
    }

    private let database: DatabaseClient
    private let apiClient: APIClient
    private let logger: AppLogger

    init(database: DatabaseClient, apiClient: APIClient, logger: AppLogger) {
        self.database = database
        self.apiClient = apiClient
        self.logger = logger
    }

    func enqueue(operation: Operation, entityId: String, payload: [String: String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let serialized = String(data: data, encoding: .utf8)
        else { return }
        database.enqueueOutbox(operation: operation.rawValue, entityId: entityId, payload: serialized)
    }

    func flush(accessToken: String?) async {
        guard let accessToken else { return }
        for item in database.fetchOutbox() {
            let payload = parsePayload(item.payload)
            do {
                if item.operation == Operation.patchProfile.rawValue {
                    let remote = try await apiClient.patchProfile(accessToken: accessToken, body: payload)
                    database.applyRemoteProfile(remote)
                } else if item.operation == Operation.uploadAvatar.rawValue {
                    if let local = payload["photo_local_uri"] {
                        let remote = try await apiClient.patchProfile(accessToken: accessToken, body: ["photo_path": local])
                        database.applyRemoteProfile(remote)
                    }
                } else if item.operation == Operation.completeOnboarding.rawValue {
                    let remote = try await apiClient.postProfileComplete(accessToken: accessToken)
                    database.applyRemoteProfile(remote)
                }
                database.deleteOutbox(id: item.id)
            } catch {
                logger.warn("outbox.flush", metadata: ["status": "failed", "operation": item.operation])
                break
            }
        }
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
