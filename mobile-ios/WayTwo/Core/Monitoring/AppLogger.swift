import Foundation
import OSLog

struct AppLogger {
    private let logger = Logger(subsystem: "com.ivankulaha.WayTwo", category: "app")

    func debug(_ message: String, metadata: [String: String] = [:]) {
        logger.debug("\(message, privacy: .public) \(metadataDescription(metadata), privacy: .public)")
    }

    func info(_ message: String, metadata: [String: String] = [:]) {
        logger.info("\(message, privacy: .public) \(metadataDescription(metadata), privacy: .public)")
    }

    func warn(_ message: String, metadata: [String: String] = [:]) {
        logger.warning("\(message, privacy: .public) \(metadataDescription(metadata), privacy: .public)")
    }

    func error(_ message: String, metadata: [String: String] = [:]) {
        logger.error("\(message, privacy: .public) \(metadataDescription(metadata), privacy: .public)")
    }

    private func metadataDescription(_ metadata: [String: String]) -> String {
        metadata.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
    }
}
