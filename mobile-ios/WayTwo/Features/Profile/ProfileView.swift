import SwiftUI

struct ProfileView: View {
    @Binding var state: ProfileReducer.State

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("onboarding.you.nameLabel", value: state.name)
                LabeledContent("auth.emailLabel", value: state.email)
            }
            .navigationTitle("tabs.profile")
            .toolbar {
                NavigationLink("profile.edit") {
                    ProfileEditView(state: $state)
                }
            }
        }
    }
}

#Preview {
    ProfileView(
        state: .constant({ var s = ProfileReducer.State(); s.name = "Alex"; s.email = "alex@example.com"; return s }())
    )
}
