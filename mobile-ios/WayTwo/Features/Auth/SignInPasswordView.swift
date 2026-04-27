import SwiftUI
import UIKit

struct SignInPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSubmit: () -> Void
    let onForgot: () -> Void

    private enum Layout {
        static let topHeaderOffset: CGFloat = Tokens.Size.authHeaderTopOffset
        static let headerToActionsGap: CGFloat = Tokens.Spacing.x4l
    }

    private var canSubmit: Bool {
        !state.password.isEmpty
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
                    Text("auth.enterPasswordTitle")
                        .font(.system(size: Tokens.FontSize.x2l, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(state.email)
                        .font(.system(size: Tokens.FontSize.md, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: contentWidth)

                Spacer().frame(height: Layout.headerToActionsGap)

                VStack(spacing: Tokens.Spacing.xl) {
                    SecureInputField(
                        placeholder: "auth.passwordPlaceholder",
                        text: $state.password,
                        textContentType: .password
                    )
                    PrimaryButton(
                        titleKey: "auth.continue",
                        isLoading: state.isLoading,
                        isDisabled: !canSubmit,
                        action: onSubmit
                    )
                    Button(action: onForgot) {
                        Text("auth.forgotPassword")
                            .font(.system(size: Tokens.FontSize.md, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
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
    SignInPasswordView(
        state: .constant({ var s = AuthReducer.State(); s.email = "hello@example.com"; return s }()),
        onSubmit: {},
        onForgot: {}
    )
}
