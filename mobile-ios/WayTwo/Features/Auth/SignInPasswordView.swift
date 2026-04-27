import SwiftUI

struct SignInPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSubmit: () -> Void
    let onForgot: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Text("auth.enterPasswordTitle")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)
            Text(state.email)
                .foregroundStyle(AppColors.textSecondary)
            SecureField("auth.passwordPlaceholder", text: $state.password)
                .padding(Tokens.Spacing.xl)
                .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.lg).stroke(AppColors.inputBorder))
            Button("auth.continue", action: onSubmit)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Button("auth.forgotPassword", action: onForgot)
                .foregroundStyle(AppColors.textSecondary)
            if let errorKey = state.errorKey {
                Text(LocalizedStringKey(errorKey))
                    .foregroundStyle(AppColors.error)
            }
        }
        .padding(Tokens.Spacing.x3l)
        .background(AppColors.surface.ignoresSafeArea())
    }
}

#Preview {
    SignInPasswordView(
        state: .constant({ var s = AuthReducer.State(); s.email = "hello@example.com"; return s }()),
        onSubmit: {},
        onForgot: {}
    )
}
