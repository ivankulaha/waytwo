import SwiftUI

struct NewPasswordView: View {
    @Binding var state: AuthReducer.State
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Text("auth.createNewPasswordTitle")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)
            SecureField("auth.newPasswordPlaceholder", text: $state.newPassword)
                .padding(Tokens.Spacing.xl)
                .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.lg).stroke(AppColors.inputBorder))
            Button("auth.savePassword", action: onSave)
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
    NewPasswordView(
        state: .constant(AuthReducer.State()),
        onSave: {}
    )
}
