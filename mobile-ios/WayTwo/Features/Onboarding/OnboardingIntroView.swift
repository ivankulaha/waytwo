import SwiftUI

struct OnboardingIntroView: View {
    @Binding var state: OnboardingReducer.State
    let onStart: () -> Void

    var body: some View {
        ZStack {
            AppColors.surface.ignoresSafeArea()
            AuthGradient()

            VStack(spacing: Tokens.Spacing.xl) {
                Spacer()
                Text("onboarding.intro.title")
                    .font(.title2)
                    .foregroundStyle(AppColors.textPrimary)
                Text("onboarding.intro.subtitle")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                PrimaryButton(titleKey: "onboarding.intro.cta", action: onStart)
            }
            .padding(Tokens.Spacing.x3l)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingIntroView(
            state: .constant(OnboardingReducer.State()),
            onStart: {}
        )
        .navigationTitle("onboarding.intro.title")
        .toolbar(.hidden, for: .navigationBar)
    }
}
