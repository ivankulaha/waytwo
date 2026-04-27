import SwiftUI

struct ForgotPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Text("auth.resetPasswordTitle")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)
            Text("auth.resetPasswordSubtitle")
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColors.textSecondary)
            TextField("auth.emailPlaceholder", text: $state.email)
                .textInputAutocapitalization(.never)
                .padding(Tokens.Spacing.xl)
                .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.lg).stroke(AppColors.inputBorder))
            Button("auth.continue", action: onSubmit)
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
    ForgotPasswordView(
        state: .constant(AuthReducer.State()),
        onSubmit: {}
    )
}
