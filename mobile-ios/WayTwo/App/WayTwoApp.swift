import SwiftData
import SwiftUI
import UIKit

@main
struct WayTwoApp: App {
    private let appContainer = AppContainer.live
    @State private var appState = AppReducer.State()

    init() {
        Self.configureSegmentedControlAppearanceForDarkForms()
    }

    var body: some Scene {
        WindowGroup {
            AppView(state: $appState, container: appContainer)
                .task {
                    if appContainer.keychain.loadSession() != nil {
                        appState.isAuthenticated = true
                    } else {
                        appState.isAuthenticated = false
                    }
                }
                .onOpenURL { url in
                    Task {
                        await handleIncomingURL(url)
                    }
                }
        }
        .modelContainer(appContainer.database.modelContainer)
    }

    /// `UISegmentedControl` defaults are unreadable on black; use explicit UIColors (avoid `UIColor(Color)`).
    private static func configureSegmentedControlAppearanceForDarkForms() {
        let seg = UISegmentedControl.appearance()
        seg.selectedSegmentTintColor = UIColor.white
        seg.setTitleTextAttributes(
            [.foregroundColor: UIColor(white: 1, alpha: 0.75)],
            for: .normal
        )
        seg.setTitleTextAttributes(
            [.foregroundColor: UIColor.black],
            for: .selected
        )
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
