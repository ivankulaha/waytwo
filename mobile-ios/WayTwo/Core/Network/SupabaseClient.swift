import Foundation
import Supabase

struct SupabaseClient {
    struct SessionTokens: Codable {
        let accessToken: String
        let refreshToken: String
    }

    let baseURL: URL
    private let logger: AppLogger
    private let client: Supabase.SupabaseClient

    init(baseURL: URL, anonKey: String, logger: AppLogger) {
        self.baseURL = baseURL
        self.logger = logger
        client = Supabase.SupabaseClient(
            supabaseURL: baseURL,
            supabaseKey: anonKey
        )
    }

    func signInWithPassword(email: String, password: String) async throws -> SessionTokens {
        let session = try await client.auth.signIn(email: email, password: password)
        logger.info("supabase.signIn", metadata: ["status": "ok"])
        return SessionTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
    }

    func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
        logger.info("supabase.signUp", metadata: ["status": "ok"])
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func updatePassword(_ password: String) async throws {
        try await client.auth.update(user: UserAttributes(password: password))
    }

    func exchangeCodeForSession(url: URL) async throws -> SessionTokens {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let code = components?.queryItems?.first(where: { $0.name == "code" })?.value ?? ""
        let session = try await client.auth.exchangeCodeForSession(authCode: code)
        return SessionTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> SessionTokens {
        let session = try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        return SessionTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
    }

    func readSession() async throws -> SessionTokens? {
        let session = try await client.auth.session
        return SessionTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
    }
}
