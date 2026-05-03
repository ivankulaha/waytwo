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
                    if appContainer.keychain.loadSession() != nil {
                        appState.isAuthenticated = true
                        appContainer.database.ensureProfileRow(userId: "local")
                        if let profile = appContainer.database.getProfile() {
                            if profile.onboardingCompletedAt != nil {
                                appState.hasCompletedOnboarding = true
                            } else {
                                appState.onboarding.name = profile.displayName ?? ""
                                appState.onboarding.gender = profile.gender ?? ""
                                appState.onboarding.dateOfBirth = profile.dateOfBirth ?? ""
                            }
                        }
                        Task { await appContainer.syncCoordinator.sessionBecameActive() }
                    } else {
                        appState.isAuthenticated = false
                    }
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
