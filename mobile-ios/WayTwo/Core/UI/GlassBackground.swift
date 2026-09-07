import SwiftUI

struct GlassPanelBackground: ViewModifier {
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.12), location: 0),
                                    .init(color: Color.clear, location: 0.5),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .allowsHitTesting(false)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

struct GlassCircleBackground: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                }
                .overlay {
                    Circle()
                        .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                        .allowsHitTesting(false)
                }
        }
    }
}
