import SwiftUI
import UIKit

struct SecureInputField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var textContentType: UITextContentType?

    @FocusState private var isFocused: Bool

    init(
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        textContentType: UITextContentType? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.textContentType = textContentType
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Spacing.xxs) {
            if !text.isEmpty {
                Text(placeholder)
                    .font(.system(size: Tokens.FontSize.sm, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            field
        }
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
        .padding(.horizontal, Tokens.Spacing.lg)
        .frame(height: Tokens.Size.inputHeight, alignment: .center)
        .background(AppColors.inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.Radius.md)
                .stroke(isFocused ? AppColors.inputBorderFocused : AppColors.inputBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var field: some View {
        let base = SecureField(
            "",
            text: $text,
            prompt: text.isEmpty
                ? Text(placeholder).foregroundStyle(AppColors.textPlaceholder)
                : nil
        )
            .focused($isFocused)
            .font(.system(size: Tokens.FontSize.lg, weight: .medium))
            .foregroundStyle(AppColors.textPrimary)
            .tint(AppColors.textPrimary)
        if let textContentType {
            base.textContentType(textContentType)
        } else {
            base
        }
    }
}

#Preview("Empty") {
    ZStack {
        AppColors.surface.ignoresSafeArea()
        SecureInputField(
            placeholder: "auth.passwordPlaceholder",
            text: .constant("")
        )
        .padding(.horizontal, Tokens.Spacing.xl)
    }
}

#Preview("Filled") {
    ZStack {
        AppColors.surface.ignoresSafeArea()
        SecureInputField(
            placeholder: "auth.passwordPlaceholder",
            text: .constant("secret")
        )
        .padding(.horizontal, Tokens.Spacing.xl)
    }
}
