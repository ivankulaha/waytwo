import SwiftData
import SwiftUI

@main
struct WayTwoApp: App {
    private let appContainer = AppContainer.live
    @State private var appState = AppReducer.State()

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
