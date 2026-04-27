import SwiftUI

struct HomeView: View {
    @Binding var state: HomeReducer.State

    var body: some View {
        NavigationStack {
            ZStack {
                Gradients.homeGlow(color: AppColors.profilePalette[state.colorId] ?? AppColors.profileFallback)
                    .ignoresSafeArea()
                VStack(spacing: Tokens.Spacing.xl) {
                    Circle()
                        .fill(AppColors.profilePalette[state.colorId] ?? AppColors.profileFallback)
                        .frame(width: Tokens.Size.avatar, height: Tokens.Size.avatar)
                    Text(state.displayName.isEmpty ? "home.title" : state.displayName)
                        .font(.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Button("home.invitePartner") {
                        state.invitePending = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(Tokens.Spacing.x3l)
            }
            .navigationTitle("tabs.home")
            .background(AppColors.homeBackground.ignoresSafeArea())
        }
    }
}

#Preview {
    HomeView(
        state: .constant({ var s = HomeReducer.State(); s.displayName = "Alex"; return s }())
    )
}
