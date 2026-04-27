import SwiftUI
import UIKit

struct NewPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSave: () -> Void

    private enum Layout {
        static let topHeaderOffset: CGFloat = Tokens.Size.authHeaderTopOffset
        static let headerToActionsGap: CGFloat = Tokens.Spacing.x4l
    }

    private var canSubmit: Bool {
        !state.newPassword.isEmpty
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

                Text("auth.createNewPasswordTitle")
                    .font(.system(size: Tokens.FontSize.x2l, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: contentWidth)

                Spacer().frame(height: Layout.headerToActionsGap)

                VStack(spacing: Tokens.Spacing.xl) {
                    SecureInputField(
                        placeholder: "auth.newPasswordPlaceholder",
                        text: $state.newPassword,
                        textContentType: .newPassword
                    )
                    PrimaryButton(
                        titleKey: "auth.savePassword",
                        isLoading: state.isLoading,
                        isDisabled: !canSubmit,
                        action: onSave
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
    NewPasswordView(
        state: .constant(AuthReducer.State()),
        onSave: {}
    )
}
