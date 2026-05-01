import Auth
import Foundation
import Supabase

struct SupabaseClient {
    struct SessionTokens: Codable {
        let accessToken: String
        let refreshToken: String
    }

    private let logger: AppLogger
    private let client: Supabase.SupabaseClient

    init(baseURL: URL, publishableKey: String, logger: AppLogger) {
        self.logger = logger
        client = Supabase.SupabaseClient(
            supabaseURL: baseURL,
            supabaseKey: publishableKey
        )
    }

    func signInWithPassword(email: String, password: String) async throws -> SessionTokens {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return SessionTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
        } catch {
            logSupabaseAuthFailure(op: "supabase.signIn", error: error)
            throw error
        }
    }

    func signUp(email: String, password: String) async throws {
        do {
            _ = try await client.auth.signUp(email: email, password: password)
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
            return SessionTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
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
            return SessionTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
        } catch {
            logSupabaseAuthFailure(op: "supabase.signInApple", error: error)
            throw error
        }
    }

    func readSession() async throws -> SessionTokens? {
        let session = try await client.auth.session
        return SessionTokens(accessToken: session.accessToken, refreshToken: session.refreshToken)
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
