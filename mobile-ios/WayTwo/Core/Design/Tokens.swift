import Foundation
import SwiftUI

enum Tokens {
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let x2l: CGFloat = 20
        static let x3l: CGFloat = 24
        static let x4l: CGFloat = 32
        static let x5l: CGFloat = 40
        static let x6l: CGFloat = 56
        static let swatchRowGap: CGFloat = 10
    }

    enum Radius {
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        /// Figma onboarding profile color glass panel (`124:6297`, `326:6080`).
        static let glassPanel: CGFloat = 26
        static let full: CGFloat = 28
    }

    enum FontSize {
        static let sm: CGFloat = 13
        static let md: CGFloat = 14
        static let lg: CGFloat = 16
        static let xl: CGFloat = 17
        static let x2l: CGFloat = 24
    }

    enum Size {
        static let contentWidth: CGFloat = 370
        static let compactCtaWidth: CGFloat = 149
        static let compactCtaHeight: CGFloat = 48
        /// Figma onboarding v2 form rows + RN `Size.inputHeight` (`326:5994` frames 8–10).
        static let inputHeight: CGFloat = 56
        /// Matches RN primary CTA height on dark forms.
        static let buttonHeight: CGFloat = 56
        /// Figma v2 onboarding form: centered primary CTA width (frames 8–10).
        static let onboardingFormPrimaryCtaWidth: CGFloat = 200
        /// Label typography on `PrimaryButton` (Figma: 24 line height).
        static let primaryButtonLabelLineHeight: CGFloat = 24
        static let avatar: CGFloat = 120
        static let swatchTap: CGFloat = 48
        static let swatchInner: CGFloat = 36
        static let dividerThickness: CGFloat = 1
        static let iconButtonSize: CGFloat = 44
    }

    enum Opacity {
        static let disabled: CGFloat = 0.45
        static let pressed: CGFloat = 0.85
        static let appleDisabled: CGFloat = 0.5
    }

    /// Vertical rhythm for scrollable form-style screens (auth, email sent, etc.).
    enum FormScreen {
        enum Spacing {
            /// Standard iOS inline navigation bar height.
            static let navBarHeight: CGFloat = 44
            /// Space before the screen header when the nav bar is hidden (no back button).
            static let beforeHeader: CGFloat = 48
            /// Space before the screen header when the nav bar is visible (back button present).
            /// Subtracts the nav bar height so the title lands at the same visual position.
            static let beforeHeaderWithNavBar: CGFloat = max(0, beforeHeader - navBarHeight)
            /// Space between primary title (header L) and subheader.
            static let headerToSubheader: CGFloat = Tokens.Spacing.md
            /// Space between the full header block and the first field or action stack.
            static let headerBlockToForm: CGFloat = Tokens.Spacing.x4l
            /// Space between stacked inputs and primary actions inside the form.
            static let formControls: CGFloat = Tokens.Spacing.xl
            /// Space between stacked name / gender / DOB rows (Figma v2 frames 8–10).
            static let onboardingStackedFieldGap: CGFloat = 68
        }

        enum Typography {
            /// Primary screen title (design “header L”).
            static let headerLine: CGFloat = Tokens.FontSize.x2l
            static let subheaderLine: CGFloat = Tokens.FontSize.md
        }

        enum Layout {
            /// Invisible subheader row on title-only screens (aligns with two-line subheader).
            static let subheaderPlaceholderHeight: CGFloat = Tokens.FontSize.md * 2.5
            /// Min height for a subheader caption (e.g. email) to match that block.
            static let subheaderBlockMinHeight: CGFloat = Tokens.FontSize.md * 2.5
        }
    }
}
