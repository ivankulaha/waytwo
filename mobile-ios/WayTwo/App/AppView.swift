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
                    .hidesNavigationBarTitle()
                    .navigationDestination(isPresented: forgotDestinationBinding) {
                        ForgotPasswordView(
                            state: $state.auth,
                            onSubmit: resetPassword
                        )
                        .navigationTitle("auth.resetPasswordTitle")
                        .hidesNavigationBarTitle()
                        .navigationDestination(isPresented: emailSentDestinationBinding) {
                            emailSentView
                                .navigationTitle("auth.emailSentTitle")
                                .hidesNavigationBarTitle()
                        }
                    }
                }
                .navigationDestination(isPresented: signUpDestinationBinding) {
                    SignUpView(
                        state: $state.auth,
                        onSignUp: signUp
                    )
                    .navigationTitle("auth.createAccountTitle")
                    .hidesNavigationBarTitle()
                }
                .navigationDestination(isPresented: newPasswordDestinationBinding) {
                    NewPasswordView(state: $state.auth, onSave: updatePassword)
                        .navigationTitle("auth.createNewPasswordTitle")
                        .hidesNavigationBarTitle()
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
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: Binding(
                get: { state.onboarding.step == .you || state.onboarding.step == .look },
                set: { if !$0 { state.onboarding.step = .intro } }
            )) {
                OnboardingYouView(state: $state.onboarding) {
                    saveOnboardingYouStep()
                    state.onboarding.step = .look
                }
                .navigationTitle("onboarding.you.title")
                .hidesNavigationBarTitle()
                .navigationDestination(isPresented: Binding(
                    get: { state.onboarding.step == .look },
                    set: { if !$0 { state.onboarding.step = .you } }
                )) {
                    OnboardingLookView(state: $state.onboarding) {
                        Task {
                            await completeOnboarding()
                        }
                    }
                    .navigationTitle("onboarding.look.title")
                    .hidesNavigationBarTitle()
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

}

