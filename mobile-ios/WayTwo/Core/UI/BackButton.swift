import SwiftUI

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Group {
            if #available(iOS 26, *) {
                Button(action: action) {
                    Image(systemName: "arrow.backward")
                        .font(.system(size: Tokens.FontSize.xl, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: Tokens.Size.iconButtonSize, height: Tokens.Size.iconButtonSize)
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.glass)
                .accessibilityLabel(Text("common.back"))
            } else {
                Button(action: action) {
                    Image(systemName: "arrow.backward")
                        .font(.system(size: Tokens.FontSize.xl, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: Tokens.Size.iconButtonSize, height: Tokens.Size.iconButtonSize)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Circle())
                .accessibilityLabel(Text("common.back"))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BackButton(action: {})
    }
}
