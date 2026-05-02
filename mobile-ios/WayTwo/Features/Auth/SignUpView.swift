import SwiftUI
import UIKit

struct SignUpView: View {
    @Binding var state: AuthReducer.State
    let onSignUp: () -> Void

    private var canSubmit: Bool {
        !state.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
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
        FormScreenScrollContainer(topSpacing: Tokens.FormScreen.Spacing.beforeHeaderWithNavBar) {
            VStack(spacing: Tokens.FormScreen.Spacing.headerToSubheader) {
                FormScreenTitleText(titleKey: "auth.createAccountTitle")
                FormScreenSubheaderPlaceholder()
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
                    SecureInputField(
                        placeholder: "auth.passwordPlaceholder",
                        text: $state.password,
                        textContentType: .newPassword
                    )
                    PrimaryButton(
                        titleKey: "auth.continue",
                        isLoading: state.isLoading,
                        isDisabled: !canSubmit,
                        action: onSignUp
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
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                SignUpView(
                    state: .constant(AuthReducer.State()),
                    onSignUp: {}
                )
                .navigationTitle("auth.createAccountTitle")
                .hidesNavigationBarTitle()
            }
    }
}
