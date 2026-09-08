import Foundation

/// Supplies a bearer token for authenticated `APIClient` requests. Implemented
/// by `SupabaseClient`, which sources tokens from the Supabase SDK's own
/// session (persisted and auto-refreshed independently of `KeychainClient`).
protocol TokenSource {
    /// A token guaranteed valid at the time of return; the SDK refreshes
    /// under the hood if the persisted session is at/near expiry.
    func currentAccessToken() async throws -> String

    /// One-shot forced refresh, used only after a real 401 from our backend
    /// (covers server-side revocation the SDK's local expiry check can't see).
    func forceRefresh() async throws -> String
}

enum APIError: Error, Equatable {
    case http(statusCode: Int)
    case decoding
}

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
    private let session: URLSession
    private let retryDelays: [TimeInterval]
    private let maxAttempts: Int

    init(
        baseURL: URL,
        logger: AppLogger,
        session: URLSession = .shared,
        retryDelays: [TimeInterval] = [0.5, 1.0, 2.0],
        maxAttempts: Int = 3
    ) {
        self.baseURL = baseURL
        self.logger = logger
        self.session = session
        self.retryDelays = retryDelays
        self.maxAttempts = maxAttempts
    }

    func checkEmailRegistered(email: String) async throws -> Bool {
        struct Request: Encodable { let email: String }
        struct Response: Decodable { let registered: Bool }
        let response: Response = try await request(path: "/auth/check-email", method: "POST", body: Request(email: email))
        return response.registered
    }

    func fetchProfile(tokenSource: TokenSource) async throws -> ProfileRow {
        try await request(path: "/me/profile", method: "GET", tokenSource: tokenSource)
    }

    func patchProfile(tokenSource: TokenSource, body: [String: String]) async throws -> ProfileRow {
        try await request(path: "/me/profile", method: "PATCH", body: body, tokenSource: tokenSource)
    }

    func postProfileComplete(tokenSource: TokenSource) async throws -> ProfileRow {
        try await request(path: "/me/profile/complete", method: "POST", tokenSource: tokenSource)
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        tokenSource: TokenSource? = nil
    ) async throws -> T {
        try await request(path: path, method: method, body: Optional<String>.none, tokenSource: tokenSource)
    }

    private func request<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body? = nil,
        tokenSource: TokenSource? = nil
    ) async throws -> T {
        var attempt = 1
        while true {
            do {
                return try await performRequest(path: path, method: method, body: body, tokenSource: tokenSource)
            } catch {
                let canRetry = Self.isRetryable(error) && attempt < maxAttempts
                if !canRetry {
                    throw error
                }
                logger.warn("api.request.retry", metadata: [
                    "attempt": "\(attempt)",
                    "method": method,
                    "path": path,
                    "status": "retry"
                ])
                let delayIndex = attempt - 1
                if delayIndex < retryDelays.count {
                    let delay = retryDelays[delayIndex]
                    if delay > 0 {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                }
                attempt += 1
            }
        }
    }

    private func performRequest<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        tokenSource: TokenSource?
    ) async throws -> T {
        logger.debug("api.request.start", metadata: [
            "host": baseURL.host ?? "unknown",
            "method": method,
            "path": path
        ])

        let accessToken = try await tokenSource?.currentAccessToken()
        let (data, httpResponse) = try await send(path: path, method: method, body: body, accessToken: accessToken)

        if httpResponse.statusCode == 401, let tokenSource {
            logger.warn("api.request.unauthorized", metadata: ["method": method, "path": path])
            let refreshedToken = try await tokenSource.forceRefresh()
            let (retryData, retryResponse) = try await send(path: path, method: method, body: body, accessToken: refreshedToken)
            return try decode(retryData, response: retryResponse, method: method, path: path)
        }

        return try decode(data, response: httpResponse, method: method, path: path)
    }

    private static func isRetryable(_ error: Error) -> Bool {
        if error is URLError { return true }
        if let apiError = error as? APIError, case .http(let statusCode) = apiError, statusCode >= 500 {
            return true
        }
        return false
    }

    private func send<Body: Encodable>(
        path: String,
        method: String,
        body: Body?,
        accessToken: String?
    ) async throws -> (Data, HTTPURLResponse) {
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

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            return (data, httpResponse)
        } catch let error as URLError {
            logger.warn("api.request.transport", metadata: [
                "code": "\(error.errorCode)",
                "method": method,
                "path": path,
                "status": "failed"
            ])
            throw error
        }
    }

    private func decode<T: Decodable>(_ data: Data, response: HTTPURLResponse, method: String, path: String) throws -> T {
        guard (200..<300).contains(response.statusCode) else {
            logger.warn("api.request.failed", metadata: [
                "method": method,
                "path": path,
                "statusCode": "\(response.statusCode)",
                "status": "failed"
            ])
            throw APIError.http(statusCode: response.statusCode)
        }

        logger.info("api.request.completed", metadata: [
            "method": method,
            "path": path,
            "statusCode": "\(response.statusCode)"
        ])

        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            logger.debug("api.decode.success", metadata: ["method": method, "path": path])
            return decoded
        } catch {
            logger.warn("api.decode.failed", metadata: ["method": method, "path": path, "status": "failed"])
            throw APIError.decoding
        }
    }
}
