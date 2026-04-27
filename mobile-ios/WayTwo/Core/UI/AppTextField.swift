import SwiftUI
import UIKit

struct AppTextField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrectionDisabled: Bool = false
    var textContentType: UITextContentType?

    @FocusState private var isFocused: Bool

    init(
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: TextInputAutocapitalization = .sentences,
        autocorrectionDisabled: Bool = false,
        textContentType: UITextContentType? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
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
        .padding(.horizontal, Tokens.Spacing.xl)
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
        let base = TextField("", text: $text, prompt: text.isEmpty ? Text(placeholder) : nil)
            .focused($isFocused)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled(autocorrectionDisabled)
            .keyboardType(keyboardType)
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
        AppTextField(
            placeholder: "auth.emailPlaceholder",
            text: .constant("")
        )
        .padding(.horizontal, Tokens.Spacing.xl)
    }
}

#Preview("Filled") {
    ZStack {
        AppColors.surface.ignoresSafeArea()
        AppTextField(
            placeholder: "auth.emailPlaceholder",
            text: .constant("sample@gmail.com")
        )
        .padding(.horizontal, Tokens.Spacing.xl)
    }
}
