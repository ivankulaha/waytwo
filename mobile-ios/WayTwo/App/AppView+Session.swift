import SwiftUI

extension AppView {
    func logout() async {
        do {
            try await container.supabase.signOut()
            container.keychain.deleteSession()
            state = AppReducer.State()
        } catch {
            state.settings.errorKey = "error.title"
        }
    }
}
