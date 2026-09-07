import SwiftData
import SwiftUI
import UIKit

@main
struct WayTwoApp: App {
    private let appContainer = AppContainer.live
    @State private var appState = AppReducer.State()

    init() {
        Self.configureSegmentedControlAppearance()
        Self.configureNavigationBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootContent(appContainer: appContainer, appState: $appState)
        }
        .modelContainer(appContainer.database.modelContainer)
    }

    private static func uiRGB(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: alpha)
    }

    private static func configureSegmentedControlAppearance() {
        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = UIColor { t in
            t.userInterfaceStyle == .dark ? .white : .black
        }
        seg.setTitleTextAttributes(
            [.foregroundColor: UIColor { t in
                t.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.75) : uiRGB(82, 82, 91)
            }],
            for: .normal
        )
        seg.setTitleTextAttributes(
            [.foregroundColor: UIColor { t in
                t.userInterfaceStyle == .dark ? .black : .white
            }],
            for: .selected
        )
    }

    /// Replace the system back chevron with `arrow.backward` while keeping
    /// iOS 26 glass styling, swipe-back gesture, and back-history menu.
    private static func configureNavigationBarAppearance() {
        let arrow = UIImage(systemName: "arrow.backward")?
            .withRenderingMode(.alwaysTemplate)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.setBackIndicatorImage(arrow, transitionMaskImage: arrow)

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
    }

    private struct RootContent: View {
        let appContainer: AppContainer
        @Binding var appState: AppReducer.State
        @Environment(\.scenePhase) private var scenePhase

        var body: some View {
            AppView(state: $appState, container: appContainer)
                .task {
                    appContainer.supabase.observeSessionInvalidated {
                        Task { @MainActor in
                            handleSessionInvalidated()
                        }
                    }
                    if appContainer.keychain.loadSession() != nil {
                        appState.isAuthenticated = true
                    } else {
                        appState.isAuthenticated = false
                    }
                }
                .onChange(of: appState.isAuthenticated) { _, isAuthenticated in
                    guard isAuthenticated else { return }
                    Task { await routeAfterAuthentication() }
                }
                .onChange(of: scenePhase) { _, new in
                    if new == .active {
                        appContainer.syncCoordinator.appBecameForeground()
                    }
                }
                .onOpenURL { url in
                    Task {
                        await handleIncomingURL(url)
                    }
                }
        }

        /// Routes Home vs onboarding from the backend profile, never from a
        /// leftover local cache. Runs once per sign-in / cold launch: binds
        /// (or wipes) the local cache to this auth user, then blocks
        /// `hasCompletedOnboarding` behind a fresh profile pull so a deleted
        /// and re-registered account can never land on Home from a stale row.
        private func routeAfterAuthentication() async {
            let session = appContainer.keychain.loadSession()
            let userId = resolveUserId(from: session)
            appContainer.database.prepareProfileForUser(userId)
            appState.profileRoutingReady = false
            applyProfileState()
            await appContainer.syncCoordinator.sessionBecameActive()
            applyProfileState()
            appState.profileRoutingReady = true
        }

        /// Prefers the id already saved with the session (every sign-in
        /// after this change saves it). Falls back to decoding the access
        /// token's `sub` claim for sessions saved before user id persistence
        /// existed, then persists it so future launches don't need to decode
        /// again. Returns nil only when neither source resolves, in which
        /// case the local cache is treated as untrusted.
        private func resolveUserId(from session: KeychainClient.Session?) -> String? {
            guard let session else { return nil }
            if let userId = session.userId {
                return userId
            }
            guard let subject = JWTAccessToken.subject(session.accessToken) else {
                return nil
            }
            _ = appContainer.keychain.saveSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                userId: subject
            )
            return subject
        }

        /// Single place to derive onboarding routing and draft fields from
        /// the local profile cache. Call again after a profile pull so a
        /// fresh backend row always wins over whatever was cached before
        /// sign-in.
        private func applyProfileState() {
            guard let profile = appContainer.database.getProfile() else {
                appState.hasCompletedOnboarding = false
                return
            }
            appState.hasCompletedOnboarding = ProfileCompleteness.hasFinishedOnboarding(
                displayName: profile.displayName,
                gender: profile.gender,
                onboardingCompletedAt: profile.onboardingCompletedAt
            )
            guard !appState.hasCompletedOnboarding else { return }
            appState.onboarding.name = profile.displayName ?? ""
            appState.onboarding.gender = profile.gender ?? ""
            appState.onboarding.dateOfBirth = profile.dateOfBirth ?? ""
            let hasYouStepFields = !appState.onboarding.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !appState.onboarding.gender.isEmpty
            appState.onboarding.step = hasYouStepFields ? .look : .intro
        }

        /// Fired when the Supabase SDK reports the session as genuinely dead
        /// (refresh token revoked/expired). No `signOut()` network call: the
        /// session is already gone server-side, only local cleanup is needed.
        private func handleSessionInvalidated() {
            appContainer.clearLocalSession()
            appState = AppReducer.State()
            appState.auth.errorKey = "auth.sessionExpired"
        }

        private func handleIncomingURL(_ url: URL) async {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
            let code = components.queryItems?.first(where: { $0.name == "code" })?.value
            guard code != nil else { return }
            do {
                _ = try await appContainer.supabase.exchangeCodeForSession(url: url)
                appState.auth.flow = .newPassword
            } catch {
                appState.auth.errorKey = "auth.couldNotUpdatePassword"
            }
        }
    }
}
