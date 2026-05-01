import SwiftUI
import UIKit

struct ForgotPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSubmit: () -> Void

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
        FormScreenScrollContainer(topSpacing: Tokens.FormScreen.Spacing.beforeHeaderWithNavBar) {
            VStack(spacing: Tokens.FormScreen.Spacing.headerToSubheader) {
                FormScreenTitleText(titleKey: "auth.resetPasswordTitle")
                FormScreenSubheaderText(textKey: "auth.resetPasswordSubtitle", lineLimit: 2)
            }
        } formContent: {
            VStack(spacing: 0) {
                VStack(spacing: Tokens.FormScreen.Spacing.formControls) {
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
    ForgotPasswordView(
        state: .constant(AuthReducer.State()),
        onSubmit: {}
    )
}
