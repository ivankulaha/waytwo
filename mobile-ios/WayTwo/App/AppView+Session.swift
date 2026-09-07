import SwiftUI

extension AppView {
    func logout() async {
        do {
            try await container.supabase.signOut()
            container.clearLocalSession()
            state = AppReducer.State()
        } catch {
            state.settings.errorKey = "error.title"
        }
    }
}
