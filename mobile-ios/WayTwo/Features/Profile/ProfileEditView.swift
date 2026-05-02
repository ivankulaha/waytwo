import SwiftUI

struct ProfileEditView: View {
    @Binding var state: ProfileReducer.State

    var body: some View {
        Form {
            TextField("onboarding.you.nameLabel", text: $state.name)

            TextField("auth.emailLabel", text: $state.email)
                .textInputAutocapitalization(.never)
        }
        .navigationTitle("profile.edit")
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                ProfileEditView(
                    state: .constant({ var s = ProfileReducer.State(); s.name = "Alex"; s.email = "alex@example.com"; return s }())
                )
            }
    }
}
