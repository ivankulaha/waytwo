import SwiftUI

struct AppView: View {
    @Binding var state: AppReducer.State
    let container: AppContainer

    var body: some View {
        Group {
            if !state.isAuthenticated {
                authFlow
            } else if !state.hasCompletedOnboarding {
                onboardingFlow
            } else {
                mainTabs
            }
        }
    }

    private var authFlow: some View {
        NavigationStack {
            switch state.auth.flow {
            case .email:
                SignInView(state: $state.auth, onContinueEmail: continueWithEmail, onAppleSignIn: signInWithApple)
            case .password:
                SignInPasswordView(state: $state.auth, onSubmit: signInPassword, onForgot: { state.auth.flow = .forgot })
            case .signup:
                SignUpView(state: $state.auth, onSignUp: signUp)
            case .forgot:
                ForgotPasswordView(state: $state.auth, onSubmit: resetPassword)
            case .emailSent:
                VStack(spacing: Tokens.Spacing.xl) {
                    Text("auth.emailSentTitle").font(.title2.bold()).foregroundStyle(AppColors.textPrimary)
                    Text("auth.emailSentBody").multilineTextAlignment(.center).foregroundStyle(AppColors.textSecondary)
                    Button("auth.backToSignIn") { state.auth.flow = .email }
                }
                .padding(Tokens.Spacing.x3l)
                .background(AppColors.surface.ignoresSafeArea())
            case .newPassword:
                NewPasswordView(state: $state.auth, onSave: updatePassword)
            }
        }
    }

    private var onboardingFlow: some View {
        NavigationStack {
            OnboardingIntroView(
                state: $state.onboarding,
                onStart: {
                    state.onboarding.step = .you
                }
            )
            .navigationDestination(isPresented: Binding(
                get: { state.onboarding.step == .you },
                set: { if !$0 { state.onboarding.step = .intro } }
            )) {
                OnboardingYouView(state: $state.onboarding) {
                    state.onboarding.step = .look
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { state.onboarding.step == .look },
                set: { if !$0 { state.onboarding.step = .you } }
            )) {
                OnboardingLookView(state: $state.onboarding) {
                    Task {
                        await completeOnboarding()
                    }
                }
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $state.selectedTab) {
            HomeView(state: $state.home)
                .tabItem {
                    Label("tabs.home", systemImage: "house")
                }
                .tag(AppReducer.Tab.home)

            SettingsView(state: $state.settings) {
                Task { await logout() }
            }
                .tabItem {
                    Label("settings.title", systemImage: "gearshape")
                }
                .tag(AppReducer.Tab.settings)
        }
    }

    private func continueWithEmail() {
        Task {
            do {
                let registered = try await container.api.checkEmailRegistered(email: state.auth.email)
                state.auth.flow = registered ? .password : .signup
                state.auth.errorKey = nil
            } catch {
                state.auth.errorKey = "auth.checkEmailFailed"
            }
        }
    }

    private func signInPassword() {
        Task {
            do {
                let session = try await container.supabase.signInWithPassword(email: state.auth.email, password: state.auth.password)
                _ = container.keychain.saveSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
                state.isAuthenticated = true
                state.auth.errorKey = nil
            } catch {
                state.auth.errorKey = "auth.invalidEmailOrPassword"
            }
        }
    }

    private func signUp() {
        Task {
            do {
                try await container.supabase.signUp(email: state.auth.email, password: state.auth.password)
                state.auth.flow = .email
                state.auth.errorKey = nil
            } catch {
                state.auth.errorKey = "auth.couldNotCreateAccount"
            }
        }
    }

    private func resetPassword() {
        Task {
            do {
                try await container.supabase.resetPassword(email: state.auth.email)
                state.auth.flow = .emailSent
            } catch {
                state.auth.errorKey = "auth.couldNotSendReset"
            }
        }
    }

    private func updatePassword() {
        Task {
            do {
                try await container.supabase.updatePassword(state.auth.newPassword)
                state.auth.flow = .email
            } catch {
                state.auth.errorKey = "auth.couldNotUpdatePassword"
            }
        }
    }

    private func signInWithApple(idToken: String, nonce: String) {
        Task {
            do {
                let session = try await container.supabase.signInWithApple(idToken: idToken, nonce: nonce)
                _ = container.keychain.saveSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
                state.isAuthenticated = true
            } catch {
                state.auth.errorKey = "auth.appleSignInError"
            }
        }
    }

    private func completeOnboarding() async {
        let token = container.keychain.loadSession()?.accessToken
        await container.profileSync.pushCompleteOnboarding(accessToken: token)
        state.hasCompletedOnboarding = true
    }

    private func logout() async {
        do {
            try await container.supabase.signOut()
            container.keychain.deleteSession()
            state = AppReducer.State()
        } catch {
            state.settings.errorKey = "error.title"
        }
    }
}
