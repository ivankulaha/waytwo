import SwiftUI

struct SettingsView: View {
    @Binding var state: SettingsReducer.State
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: Tokens.Spacing.xl) {
                Button("settings.logOut", action: onLogout)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                if let errorKey = state.errorKey {
                    Text(LocalizedStringKey(errorKey))
                        .foregroundStyle(AppColors.error)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(Tokens.Spacing.x3l)
            .background(AppColors.settingsBackground.ignoresSafeArea())
            .navigationTitle("settings.title")
        }
    }
}

#Preview {
    SettingsView(
        state: .constant(SettingsReducer.State()),
        onLogout: {}
    )
}
