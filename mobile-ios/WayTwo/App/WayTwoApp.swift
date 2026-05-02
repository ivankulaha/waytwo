import SwiftData
import SwiftUI
import UIKit

@main
struct WayTwoApp: App {
    private let appContainer = AppContainer.live
    @State private var appState = AppReducer.State()

    init() {
        Self.configureSegmentedControlAppearance()
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
