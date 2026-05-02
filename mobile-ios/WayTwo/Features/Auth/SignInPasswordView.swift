import SwiftUI
import UIKit

struct SignInPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSubmit: () -> Void
    let onForgot: () -> Void

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
        FormScreenScrollContainer(topSpacing: Tokens.FormScreen.Spacing.beforeHeaderWithNavBar) {
            VStack(spacing: Tokens.FormScreen.Spacing.headerToSubheader) {
                FormScreenTitleText(titleKey: "auth.enterPasswordTitle")
                FormScreenSubheaderCaption(text: state.email)
            }
        } formContent: {
            VStack(spacing: 0) {
                VStack(spacing: Tokens.FormScreen.Spacing.formControls) {
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
                            .font(.system(size: Tokens.FormScreen.Typography.subheaderLine, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
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
                SignInPasswordView(
                    state: .constant({ var s = AuthReducer.State(); s.email = "hello@example.com"; return s }()),
                    onSubmit: {},
                    onForgot: {}
                )
                .navigationTitle("auth.enterPasswordTitle")
                .hidesNavigationBarTitle()
            }
    }
}
