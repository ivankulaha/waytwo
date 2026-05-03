import SwiftUI

extension AppView {
    func continueWithEmail() {
        Task {
            do {
                let registered = try await container.api.checkEmailRegistered(email: state.auth.email)
                state.auth.password = ""
                state.auth.flow = registered ? .password : .signup
                state.auth.errorKey = nil
            } catch {
                state.auth.errorKey = "auth.checkEmailFailed"
            }
        }
    }

    func signInPassword() {
        Task {
            do {
                let session = try await container.supabase.signInWithPassword(email: state.auth.email, password: state.auth.password)
                _ = container.keychain.saveSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
                state.auth.password = ""
                state.isAuthenticated = true
                container.database.ensureProfileRow(userId: "local")
                state.auth.errorKey = nil
                Task { await container.syncCoordinator.sessionBecameActive() }
            } catch {
                state.auth.errorKey = "auth.invalidEmailOrPassword"
            }
        }
    }

    func signUp() {
        Task {
            do {
                try await container.supabase.signUp(email: state.auth.email, password: state.auth.password)
                state.auth.password = ""
                state.auth.flow = .email
                state.auth.errorKey = nil
            } catch {
                state.auth.errorKey = "auth.couldNotCreateAccount"
            }
        }
    }

    func resetPassword() {
        Task {
            do {
                try await container.supabase.resetPassword(email: state.auth.email)
                state.auth.flow = .emailSent
            } catch {
                state.auth.errorKey = "auth.couldNotSendReset"
            }
        }
    }

    func updatePassword() {
        Task {
            do {
                try await container.supabase.updatePassword(state.auth.newPassword)
                state.auth.newPassword = ""
                state.auth.flow = .email
            } catch {
                state.auth.errorKey = "auth.couldNotUpdatePassword"
            }
        }
    }

    func signInWithApple(idToken: String, nonce: String) {
        Task {
            do {
                let session = try await container.supabase.signInWithApple(idToken: idToken, nonce: nonce)
                _ = container.keychain.saveSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
                state.isAuthenticated = true
                container.database.ensureProfileRow(userId: "local")
                Task { await container.syncCoordinator.sessionBecameActive() }
            } catch {
                state.auth.errorKey = "auth.appleSignInError"
            }
        }
    }
}
