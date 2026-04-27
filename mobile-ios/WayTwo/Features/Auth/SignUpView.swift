import SwiftUI

struct SignUpView: View {
    @Binding var state: AuthReducer.State
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Text("auth.createAccountTitle")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)
            TextField("auth.emailPlaceholder", text: $state.email)
                .textInputAutocapitalization(.never)
                .padding(Tokens.Spacing.xl)
                .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.lg).stroke(AppColors.inputBorder))
            SecureField("auth.passwordPlaceholder", text: $state.password)
                .padding(Tokens.Spacing.xl)
                .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.lg).stroke(AppColors.inputBorder))
            Button("auth.continue", action: onSignUp)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
    SignUpView(
        state: .constant(AuthReducer.State()),
        onSignUp: {}
    )
}
