import SwiftUI
import UIKit

/// Full-width pill CTA used across auth and onboarding flows. Mirrors the
/// React Native `<PrimaryButton>` component: capsule shape, height
/// `Tokens.Size.buttonHeight`, adaptive fill/text per Figma `2067:5163`
/// (light: black fill, dark: white fill), and disabled states from `AppColors`.
struct PrimaryButton: View {
    let titleKey: LocalizedStringKey
    var isLoading: Bool = false
    var isDisabled: Bool = false
    /// When set (e.g. onboarding form CTA), caps width instead of expanding to the container.
    var maxContentWidth: CGFloat? = nil
    let action: () -> Void

    private var inactive: Bool { isLoading || isDisabled }

    private static var titleLineSpacing: CGFloat {
        let uiFont = UIFont.systemFont(ofSize: Tokens.FontSize.lg, weight: .semibold)
        return max(0, Tokens.Size.primaryButtonLabelLineHeight - uiFont.lineHeight)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(inactive ? AppColors.buttonDisabledText : AppColors.buttonText)
                } else {
                    Text(titleKey)
                        .font(.system(size: Tokens.FontSize.lg, weight: .semibold))
                        .lineSpacing(Self.titleLineSpacing)
                        .foregroundStyle(inactive ? AppColors.buttonDisabledText : AppColors.buttonText)
                }
            }
            .frame(maxWidth: maxContentWidth ?? .infinity)
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
