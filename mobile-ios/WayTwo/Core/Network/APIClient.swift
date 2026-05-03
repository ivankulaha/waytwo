import Foundation

struct APIClient {
    struct ProfileRow: Codable {
        let userId: String
        let displayName: String?
        let gender: String?
        let dateOfBirth: String?
        let photoPath: String?
        let colorId: String?
        let onboardingStep: Int
        let onboardingCompletedAt: String?
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case displayName = "display_name"
            case gender
            case dateOfBirth = "date_of_birth"
            case photoPath = "photo_path"
            case colorId = "color_id"
            case onboardingStep = "onboarding_step"
            case onboardingCompletedAt = "onboarding_completed_at"
            case updatedAt = "updated_at"
        }
    }

    let baseURL: URL
    private let logger: AppLogger

    init(baseURL: URL, logger: AppLogger) {
        self.baseURL = baseURL
        self.logger = logger
    }

    func checkEmailRegistered(email: String) async throws -> Bool {
        struct Request: Encodable { let email: String }
        struct Response: Decodable { let registered: Bool }
        let response: Response = try await request(path: "/auth/check-email", method: "POST", body: Request(email: email))
        return response.registered
    }

    func fetchProfile(accessToken: String) async throws -> ProfileRow {
        try await request(path: "/me/profile", method: "GET", accessToken: accessToken)
    }

    func patchProfile(accessToken: String, body: [String: String]) async throws -> ProfileRow {
        try await request(path: "/me/profile", method: "PATCH", body: body, accessToken: accessToken)
    }

    func postProfileComplete(accessToken: String) async throws -> ProfileRow {
        try await request(path: "/me/profile/complete", method: "POST", accessToken: accessToken)
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        accessToken: String? = nil
    ) async throws -> T {
        try await request(path: path, method: method, body: Optional<String>.none, accessToken: accessToken)
    }

    private func request<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body? = nil,
        accessToken: String? = nil
    ) async throws -> T {
        logger.debug("api.request.start", metadata: [
            "host": baseURL.host ?? "unknown",
            "method": method,
            "path": path
        ])
        let endpoint = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            logger.warn("api.request.transport", metadata: [
                "code": "\(error.errorCode)",
                "method": method,
                "path": path,
                "status": "failed"
            ])
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            logger.warn("api.request.failed", metadata: [
                "method": method,
                "path": path,
                "status": "failed"
            ])
            throw URLError(.badServerResponse)
        }

        logger.info("api.request.completed", metadata: [
            "method": method,
            "path": path,
            "statusCode": "\(httpResponse.statusCode)"
        ])

        let decoded = try JSONDecoder().decode(T.self, from: data)
        logger.debug("api.decode.success", metadata: ["method": method, "path": path])
        return decoded
    }
}
