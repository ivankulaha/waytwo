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
            SignInView(state: $state.auth, onContinueEmail: continueWithEmail, onAppleSignIn: signInWithApple)
                .navigationTitle("auth.navSignIn")
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: passwordDestinationBinding) {
                    SignInPasswordView(
                        state: $state.auth,
                        onSubmit: signInPassword,
                        onForgot: { state.auth.flow = .forgot }
                    )
                    .navigationTitle("auth.enterPasswordTitle")
                    .authScreenWithoutVisibleNavigationTitle()
                    .navigationDestination(isPresented: forgotDestinationBinding) {
                        ForgotPasswordView(
                            state: $state.auth,
                            onSubmit: resetPassword
                        )
                        .navigationTitle("auth.resetPasswordTitle")
                        .authScreenWithoutVisibleNavigationTitle()
                        .navigationDestination(isPresented: emailSentDestinationBinding) {
                            emailSentView
                                .navigationTitle("auth.emailSentTitle")
                                .authScreenWithoutVisibleNavigationTitle()
                        }
                    }
                }
                .navigationDestination(isPresented: signUpDestinationBinding) {
                    SignUpView(
                        state: $state.auth,
                        onSignUp: signUp
                    )
                    .navigationTitle("auth.createAccountTitle")
                    .authScreenWithoutVisibleNavigationTitle()
                }
                .navigationDestination(isPresented: newPasswordDestinationBinding) {
                    NewPasswordView(state: $state.auth, onSave: updatePassword)
                        .navigationTitle("auth.createNewPasswordTitle")
                        .authScreenWithoutVisibleNavigationTitle()
                }
        }
    }

    private var passwordDestinationBinding: Binding<Bool> {
        Binding(
            get: { state.auth.flow == .password || state.auth.flow == .forgot || state.auth.flow == .emailSent },
            set: { isPresented in
                guard !isPresented else { return }
                if state.auth.flow == .password {
                    state.auth.flow = .email
                    state.auth.password = ""
                    state.auth.errorKey = nil
                }
            }
        )
    }

    private var signUpDestinationBinding: Binding<Bool> {
        Binding(
            get: { state.auth.flow == .signup },
            set: { isPresented in
                guard !isPresented else { return }
                if state.auth.flow == .signup {
                    state.auth.flow = .email
                    state.auth.password = ""
                    state.auth.errorKey = nil
                }
            }
        )
    }

    private var forgotDestinationBinding: Binding<Bool> {
        Binding(
            get: { state.auth.flow == .forgot || state.auth.flow == .emailSent },
            set: { isPresented in
                guard !isPresented else { return }
                if state.auth.flow == .forgot {
                    state.auth.flow = .password
                    state.auth.errorKey = nil
                }
            }
        )
    }

    private var emailSentDestinationBinding: Binding<Bool> {
        Binding(
            get: { state.auth.flow == .emailSent },
            set: { isPresented in
                guard !isPresented else { return }
                if state.auth.flow == .emailSent {
                    state.auth.flow = .forgot
                    state.auth.errorKey = nil
                }
            }
        )
    }

    private var newPasswordDestinationBinding: Binding<Bool> {
        Binding(
            get: { state.auth.flow == .newPassword },
            set: { isPresented in
                guard !isPresented else { return }
                if state.auth.flow == .newPassword {
                    state.auth.flow = .email
                    state.auth.newPassword = ""
                    state.auth.errorKey = nil
                }
            }
        )
    }

    private var emailSentView: some View {
        ZStack {
            AppColors.surface.ignoresSafeArea()
            AuthGradient()
            FormScreenScrollContainer {
                VStack(spacing: Tokens.FormScreen.Spacing.headerToSubheader) {
                    FormScreenTitleText(titleKey: "auth.emailSentTitle")
                    FormScreenSubheaderText(textKey: "auth.emailSentBody", lineLimit: nil)
                }
            } formContent: {
                PrimaryButton(
                    titleKey: "auth.backToSignIn",
                    action: {
                        state.auth.flow = .email
                        state.auth.password = ""
                        state.auth.newPassword = ""
                    }
                )
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
                .navigationTitle("onboarding.you.title")
                .authScreenWithoutVisibleNavigationTitle()
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
                state.auth.password = ""
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
                state.auth.password = ""
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
                state.auth.password = ""
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
                state.auth.newPassword = ""
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

private extension View {
    /// Keeps `navigationTitle` for back-stack context, but removes the visible title area in the navigation bar.
    func authScreenWithoutVisibleNavigationTitle() -> some View {
        navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                }
            }
    }
}
