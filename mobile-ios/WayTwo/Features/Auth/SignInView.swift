import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @Binding var state: AuthReducer.State
    let onContinueEmail: () -> Void
    let onAppleSignIn: (_ idToken: String, _ nonce: String) -> Void
    @FocusState private var emailFocused: Bool

    private enum Layout {
        static let topHeaderOffset: CGFloat = Tokens.Size.authHeaderTopOffset
        static let headerToActionsGap: CGFloat = Tokens.Spacing.x4l
    }

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
        GeometryReader { proxy in
            let availableWidth = max(0, proxy.size.width - (Tokens.Spacing.xl * 2))
            let contentWidth = min(Tokens.Size.contentWidth, availableWidth)

            VStack(spacing: 0) {
                Spacer().frame(height: Layout.topHeaderOffset)

                VStack(spacing: Tokens.Spacing.md) {
                    Text("auth.signInOrCreateTitle")
                        .font(.system(size: Tokens.FontSize.x2l, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("auth.signInOrCreateSubtitle")
                        .font(.system(size: Tokens.FontSize.md, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(width: contentWidth)

                Spacer().frame(height: Layout.headerToActionsGap)

                VStack(spacing: Tokens.Spacing.xl) {
                    appleButton
                    separator
                    emailField
                    PrimaryButton(
                        titleKey: "auth.continue",
                        isLoading: state.isLoading,
                        isDisabled: !canSubmit,
                        action: onContinueEmail
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

    private var emailField: some View {
        TextField(String(localized: "auth.emailPlaceholder"), text: $state.email)
            .focused($emailFocused)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(.emailAddress)
            .font(.system(size: Tokens.FontSize.lg, weight: .medium))
            .foregroundStyle(AppColors.textPrimary)
            .tint(AppColors.textPrimary)
            .padding(.horizontal, Tokens.Spacing.xl)
            .frame(height: Tokens.Size.inputHeight)
            .background(AppColors.inputBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.Radius.md)
                    .stroke(emailFocused ? AppColors.inputBorderFocused : AppColors.inputBorder, lineWidth: 1)
            )
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
