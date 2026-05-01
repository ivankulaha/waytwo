import SwiftUI

/// Scrollable form shell: top inset → header → gap → main content. Spacing and
/// title styles come from `Tokens.FormScreen`.
struct FormScreenScrollContainer<Header: View, FormContent: View>: View {
    private let topSpacing: CGFloat
    @ViewBuilder private var header: () -> Header
    @ViewBuilder private var formContent: () -> FormContent

    /// - Parameter topSpacing: Pass `Tokens.FormScreen.Spacing.beforeHeaderWithNavBar` when
    ///   the screen is pushed onto a navigation stack with a visible back button.
    init(
        topSpacing: CGFloat = Tokens.FormScreen.Spacing.beforeHeader,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder formContent: @escaping () -> FormContent
    ) {
        self.topSpacing = topSpacing
        self.header = header
        self.formContent = formContent
    }

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(0, proxy.size.width - (Tokens.Spacing.xl * 2))
            let contentWidth = min(Tokens.Size.contentWidth, availableWidth)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: topSpacing)
                    header()
                        .frame(width: contentWidth)
                    Spacer().frame(height: Tokens.FormScreen.Spacing.headerBlockToForm)
                    formContent()
                        .frame(width: contentWidth)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, Tokens.Spacing.x3l)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct FormScreenTitleText: View {
    let titleKey: LocalizedStringKey

    var body: some View {
        Text(titleKey)
            .font(.system(size: Tokens.FormScreen.Typography.headerLine, weight: .semibold))
            .foregroundStyle(AppColors.textPrimary)
            .multilineTextAlignment(.center)
    }
}

struct FormScreenSubheaderText: View {
    let textKey: LocalizedStringKey
    var lineLimit: Int? = 2

    var body: some View {
        Text(textKey)
            .font(.system(size: Tokens.FormScreen.Typography.subheaderLine, weight: .regular))
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .modifier(OptionalLineLimit(lineLimit: lineLimit))
    }
}

private struct OptionalLineLimit: ViewModifier {
    let lineLimit: Int?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let lineLimit {
            content.lineLimit(lineLimit)
        } else {
            content
        }
    }
}

struct FormScreenSubheaderCaption: View {
    let text: String
    var lineLimit: Int = 2
    var minimumScaleFactor: CGFloat = 0.85

    var body: some View {
        Text(text)
            .font(.system(size: Tokens.FormScreen.Typography.subheaderLine, weight: .regular))
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .minimumScaleFactor(minimumScaleFactor)
            .frame(minHeight: Tokens.FormScreen.Layout.subheaderBlockMinHeight, alignment: .center)
    }
}

struct FormScreenSubheaderPlaceholder: View {
    var body: some View {
        Color.clear
            .frame(height: Tokens.FormScreen.Layout.subheaderPlaceholderHeight)
    }
}
