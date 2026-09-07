import Auth
import Foundation
import Supabase

struct SupabaseClient: TokenSource {
    struct SessionTokens: Codable {
        let accessToken: String
        let refreshToken: String
        let userId: String
    }

    /// Holds the auth state listener registration. `AuthStateChangeListenerRegistration`
    /// removes itself on deinit, so this must outlive the `Task` that creates it;
    /// `SupabaseClient` is a struct held once for the app's process lifetime in
    /// `AppContainer`, and this class-backed box is shared across its copies.
    private final class ListenerBox {
        var registration: (any AuthStateChangeListenerRegistration)?
    }

    private let logger: AppLogger
    private let client: Supabase.SupabaseClient
    private let listenerBox = ListenerBox()

    init(baseURL: URL, publishableKey: String, logger: AppLogger) {
        self.logger = logger
        client = Supabase.SupabaseClient(
            supabaseURL: baseURL,
            supabaseKey: publishableKey
        )
    }

    /// A token guaranteed valid at the time of return: the Supabase SDK
    /// persists its session in its own Keychain storage (independent of
    /// `KeychainClient`) and refreshes it here if it's at/near expiry.
    func currentAccessToken() async throws -> String {
        try await client.auth.session.accessToken
    }

    /// One-shot forced refresh used only after a real 401 from our backend.
    func forceRefresh() async throws -> String {
        try await client.auth.refreshSession().accessToken
    }

    /// Fires `handler` when the SDK detects the session is genuinely dead
    /// (revoked/deleted, not just locally expired) and clears itself. Call
    /// once; the underlying listener is retained for the app's lifetime.
    func observeSessionInvalidated(_ handler: @escaping () -> Void) {
        Task {
            let registration = await client.auth.onAuthStateChange { event, _ in
                guard event == .signedOut else { return }
                handler()
            }
            listenerBox.registration = registration
        }
    }

    func signInWithPassword(email: String, password: String) async throws -> SessionTokens {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return SessionTokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id.uuidString
            )
        } catch {
            logSupabaseAuthFailure(op: "supabase.signIn", error: error)
            throw error
        }
    }

    func signUp(email: String, password: String) async throws -> SessionTokens {
        do {
            let result = try await client.auth.signUp(email: email, password: password)
            guard let session = result.session else {
                throw AuthError.sessionMissing
            }
            return SessionTokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id.uuidString
            )
        } catch {
            logSupabaseAuthFailure(op: "supabase.signUp", error: error)
            throw error
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            logSupabaseAuthFailure(op: "supabase.signOut", error: error)
            throw error
        }
    }

    func resetPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            logSupabaseAuthFailure(op: "supabase.resetPassword", error: error)
            throw error
        }
    }

    func updatePassword(_ password: String) async throws {
        do {
            try await client.auth.update(user: UserAttributes(password: password))
        } catch {
            logSupabaseAuthFailure(op: "supabase.updatePassword", error: error)
            throw error
        }
    }

    func exchangeCodeForSession(url: URL) async throws -> SessionTokens {
        do {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let code = components?.queryItems?.first(where: { $0.name == "code" })?.value ?? ""
            let session = try await client.auth.exchangeCodeForSession(authCode: code)
            return SessionTokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id.uuidString
            )
        } catch {
            logSupabaseAuthFailure(op: "supabase.exchangeCode", error: error)
            throw error
        }
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> SessionTokens {
        do {
            let session = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            return SessionTokens(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: session.user.id.uuidString
            )
        } catch {
            logSupabaseAuthFailure(op: "supabase.signInApple", error: error)
            throw error
        }
    }

    func readSession() async throws -> SessionTokens? {
        let session = try await client.auth.session
        return SessionTokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            userId: session.user.id.uuidString
        )
    }

    private func logSupabaseAuthFailure(op: String, error: Error) {
        var metadata: [String: String] = ["op": op, "status": "failed"]
        if let authError = error as? AuthError {
            metadata["kind"] = authErrorKindTag(authError)
            metadata["authErrorCode"] = authError.errorCode.rawValue
            switch authError {
            case let .api(_, _, _, response):
                metadata["httpStatus"] = "\(response.statusCode)"
            case let .weakPassword(_, reasons):
                metadata["weakPasswordReasonCount"] = "\(reasons.count)"
            case let .pkceGrantCodeExchange(_, _, code):
                if let code {
                    metadata["pkceCode"] = code
                }
            default:
                break
            }
        } else if let urlError = error as? URLError {
            metadata["errorDomain"] = URLError.errorDomain
            metadata["errorCode"] = "\(urlError.code.rawValue)"
        } else {
            let ns = error as NSError
            metadata["errorDomain"] = ns.domain
            metadata["errorCode"] = "\(ns.code)"
        }
        logger.warn("supabase.auth.failed", metadata: metadata)
    }

    private func authErrorKindTag(_ error: AuthError) -> String {
        switch error {
        case .sessionMissing: return "sessionMissing"
        case .weakPassword: return "weakPassword"
        case .api: return "api"
        case .pkceGrantCodeExchange: return "pkceGrantCodeExchange"
        case .implicitGrantRedirect: return "implicitGrantRedirect"
        case .jwtVerificationFailed: return "jwtVerificationFailed"
        case .missingExpClaim: return "missingExpClaim"
        case .malformedJWT: return "malformedJWT"
        case .invalidRedirectScheme: return "invalidRedirectScheme"
        case .missingURL: return "missingURL"
        @unknown default:
            return "unknown"
        }
    }
}
