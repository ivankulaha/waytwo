import SwiftUI
import UIKit

struct NewPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSave: () -> Void

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
        FormScreenScrollContainer(topSpacing: Tokens.FormScreen.Spacing.beforeHeaderWithNavBar) {
            VStack(spacing: Tokens.FormScreen.Spacing.headerToSubheader) {
                FormScreenTitleText(titleKey: "auth.createNewPasswordTitle")
                FormScreenSubheaderPlaceholder()
            }
        } formContent: {
            VStack(spacing: 0) {
                VStack(spacing: Tokens.FormScreen.Spacing.formControls) {
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

                if let errorKey = state.errorKey {
                    Text(LocalizedStringKey(errorKey))
                        .foregroundStyle(AppColors.error)
                        .font(.system(size: Tokens.FontSize.sm, weight: .regular))
                        .multilineTextAlignment(.center)
                        .padding(.top, Tokens.Spacing.x2l)
                }
            }
        }
    }

}

#Preview {
    NewPasswordView(
        state: .constant(AuthReducer.State()),
        onSave: {}
    )
}
