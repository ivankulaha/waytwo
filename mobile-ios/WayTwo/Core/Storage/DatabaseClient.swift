import Foundation
import SwiftData

@Model
final class ProfileRecord {
    var id: Int
    var userId: String
    var displayName: String?
    var gender: String?
    var dateOfBirth: String?
    var photoPath: String?
    var colorId: String?
    var onboardingStep: Int
    var onboardingCompletedAt: String?
    var photoLocalURI: String?
    var photoPending: Bool
    var dirty: Bool
    var lastSyncedAt: String?
    var remoteUpdatedAt: String?
    var updatedAt: Date

    init(id: Int = 1, userId: String, updatedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        displayName = nil
        gender = nil
        dateOfBirth = nil
        photoPath = nil
        colorId = nil
        onboardingStep = 0
        onboardingCompletedAt = nil
        photoLocalURI = nil
        photoPending = false
        dirty = false
        lastSyncedAt = nil
        remoteUpdatedAt = nil
        self.updatedAt = updatedAt
    }
}

@Model
final class OutboxRecord {
    var id: UUID
    var operation: String
    var entityId: String
    var payload: String
    var createdAt: Date
    var attempts: Int
    var lastErrorAt: Date?
    var lastErrorMessage: String?

    init(id: UUID = UUID(), operation: String, entityId: String, payload: String, createdAt: Date = Date()) {
        self.id = id
        self.operation = operation
        self.entityId = entityId
        self.payload = payload
        self.createdAt = createdAt
        attempts = 0
        lastErrorAt = nil
        lastErrorMessage = nil
    }
}

final class DatabaseClient {
    let modelContainer: ModelContainer
    private let logger: AppLogger

    init(logger: AppLogger) {
        self.logger = logger
        let schema = Schema([ProfileRecord.self, OutboxRecord.self])
        let fileManager = FileManager.default

        do {
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let storeDirectoryURL = appSupportURL.appendingPathComponent("WayTwo", isDirectory: true)
            try fileManager.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true)
            let storeURL = storeDirectoryURL.appendingPathComponent("default.store")
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to initialize SwiftData: \(error.localizedDescription)")
        }
    }

    func ensureProfileRow(userId: String) {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ProfileRecord>(predicate: #Predicate { $0.id == 1 })
        guard (try? context.fetch(descriptor).first) == nil else { return }
        let record = ProfileRecord(userId: userId)
        context.insert(record)
        try? context.save()
    }

    func applyRemoteProfile(_ remote: APIClient.ProfileRow) {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ProfileRecord>(predicate: #Predicate { $0.id == 1 })
        let record = (try? context.fetch(descriptor).first) ?? ProfileRecord(userId: remote.userId)
        record.displayName = remote.displayName
        record.gender = remote.gender
        record.dateOfBirth = remote.dateOfBirth
        record.photoPath = remote.photoPath
        record.colorId = remote.colorId
        record.onboardingStep = remote.onboardingStep
        record.onboardingCompletedAt = remote.onboardingCompletedAt
        record.remoteUpdatedAt = remote.updatedAt
        record.lastSyncedAt = ISO8601DateFormatter().string(from: Date())
        record.dirty = false
        record.updatedAt = Date()
        context.insert(record)
        try? context.save()
    }

    func upsertProfileFields(_ fields: [String: String]) {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ProfileRecord>(predicate: #Predicate { $0.id == 1 })
        guard let record = try? context.fetch(descriptor).first else { return }
        if let displayName = fields["display_name"] { record.displayName = displayName }
        if let gender = fields["gender"] { record.gender = gender }
        if let dateOfBirth = fields["date_of_birth"] { record.dateOfBirth = dateOfBirth }
        if let colorId = fields["color_id"] { record.colorId = colorId }
        if let photoPath = fields["photo_path"] { record.photoPath = photoPath }
        record.dirty = true
        record.updatedAt = Date()
        try? context.save()
    }

    func getProfile() -> ProfileRecord? {
        let descriptor = FetchDescriptor<ProfileRecord>(predicate: #Predicate { $0.id == 1 })
        return try? modelContainer.mainContext.fetch(descriptor).first
    }

    func enqueueOutbox(operation: String, entityId: String, payload: String) {
        let context = modelContainer.mainContext
        context.insert(OutboxRecord(operation: operation, entityId: entityId, payload: payload))
        try? context.save()
        logger.debug("outbox.enqueue", metadata: ["operation": operation])
    }

    func fetchOutbox(limit: Int = 20) -> [OutboxRecord] {
        let descriptor = FetchDescriptor<OutboxRecord>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
        return (try? modelContainer.mainContext.fetch(descriptor))?.prefix(limit).map { $0 } ?? []
    }

    func deleteOutbox(id: UUID) {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<OutboxRecord>(predicate: #Predicate { $0.id == id })
        if let record = try? context.fetch(descriptor).first {
            context.delete(record)
            try? context.save()
        }
    }
}
