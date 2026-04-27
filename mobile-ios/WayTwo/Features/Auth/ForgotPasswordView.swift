import SwiftUI
import UIKit

struct ForgotPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSubmit: () -> Void

    private enum Layout {
        static let topHeaderOffset: CGFloat = Tokens.Size.authHeaderTopOffset
        static let headerToActionsGap: CGFloat = Tokens.Spacing.x4l
    }

    private var canSubmit: Bool {
        !state.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppColors.surface.ignoresSafeArea()
            AuthGradient()
            content
        }
    }

    private var content: some View {
        GeometryReader { proxy in
            let availableWidth = max(0, proxy.size.width - (Tokens.Spacing.xl * 2))
            let contentWidth = min(Tokens.Size.contentWidth, availableWidth)

            VStack(spacing: 0) {
                Spacer().frame(height: Layout.topHeaderOffset)

                VStack(spacing: Tokens.Spacing.md) {
                    Text("auth.resetPasswordTitle")
                        .font(.system(size: Tokens.FontSize.x2l, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("auth.resetPasswordSubtitle")
                        .font(.system(size: Tokens.FontSize.md, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: contentWidth)

                Spacer().frame(height: Layout.headerToActionsGap)

                VStack(spacing: Tokens.Spacing.xl) {
                    AppTextField(
                        placeholder: "auth.emailPlaceholder",
                        text: $state.email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        autocorrectionDisabled: true,
                        textContentType: .username
                    )
                    PrimaryButton(
                        titleKey: "auth.continue",
                        isLoading: state.isLoading,
                        isDisabled: !canSubmit,
                        action: onSubmit
                    )
                }
                .frame(width: contentWidth)

                if let errorKey = state.errorKey {
                    Text(LocalizedStringKey(errorKey))
                        .foregroundStyle(AppColors.error)
                        .font(.system(size: Tokens.FontSize.sm, weight: .regular))
                        .multilineTextAlignment(.center)
                        .padding(.top, Tokens.Spacing.x2l)
                        .frame(width: contentWidth)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }

}

#Preview {
    ForgotPasswordView(
        state: .constant(AuthReducer.State()),
        onSubmit: {}
    )
}
