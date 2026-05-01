import SwiftUI
import AuthenticationServices
import CryptoKit
import UIKit

struct SignInView: View {
    @Binding var state: AuthReducer.State
    let onContinueEmail: () -> Void
    let onAppleSignIn: (_ idToken: String, _ nonce: String) -> Void

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
        FormScreenScrollContainer {
            VStack(spacing: Tokens.FormScreen.Spacing.headerToSubheader) {
                FormScreenTitleText(titleKey: "auth.signInOrCreateTitle")
                FormScreenSubheaderText(textKey: "auth.signInOrCreateSubtitle", lineLimit: 2)
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
                        action: onContinueEmail
                    )
                    separator
                    appleButton
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

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = UUID().uuidString
            state.appleNonce = nonce
            request.requestedScopes = [.email, .fullName]
            request.nonce = sha256(nonce)
        } onCompletion: { result in
            guard case let .success(auth) = result,
                  let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8)
            else {
                state.errorKey = "auth.appleSignInError"
                return
            }
            onAppleSignIn(token, state.appleNonce)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: Tokens.Size.buttonHeight)
        .clipShape(Capsule())
        .contentShape(Capsule())
    }

    private var separator: some View {
        HStack(spacing: Tokens.Spacing.lg) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: Tokens.Size.dividerThickness)
            Text("auth.or")
                .font(.system(size: Tokens.FontSize.md, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: Tokens.Size.dividerThickness)
        }
    }

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview("Empty") {
    SignInView(
        state: .constant(AuthReducer.State()),
        onContinueEmail: {},
        onAppleSignIn: { _, _ in }
    )
}

#Preview("With email") {
    SignInView(
        state: .constant({ var s = AuthReducer.State(); s.email = "hello@example.com"; return s }()),
        onContinueEmail: {},
        onAppleSignIn: { _, _ in }
    )
}
