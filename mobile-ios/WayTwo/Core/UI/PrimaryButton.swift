import SwiftUI

/// Full-width pill CTA used across auth and onboarding flows. Mirrors the
/// React Native `<PrimaryButton>` component: capsule shape, height
/// `Tokens.Size.buttonHeight`, white background in dark theme, and a
/// dark-grey disabled state matching `palette.buttonDisabledBgDark`.
struct PrimaryButton: View {
    let titleKey: LocalizedStringKey
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    private var inactive: Bool { isLoading || isDisabled }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(inactive ? AppColors.buttonDisabledText : AppColors.buttonText)
                } else {
                    Text(titleKey)
                        .font(.system(size: Tokens.FontSize.xl, weight: .semibold))
                        .foregroundStyle(inactive ? AppColors.buttonDisabledText : AppColors.buttonText)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Tokens.Size.buttonHeight)
            .background(inactive ? AppColors.buttonDisabledBackground : AppColors.buttonBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(inactive)
    }
}

#Preview {
    VStack(spacing: Tokens.Spacing.xl) {
        PrimaryButton(titleKey: "auth.continue") {}
        PrimaryButton(titleKey: "auth.continue", isDisabled: true) {}
        PrimaryButton(titleKey: "auth.continue", isLoading: true) {}
    }
    .padding(Tokens.Spacing.x3l)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppColors.surface)
}
