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
    }

    enum Radius {
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
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
        static let inputHeight: CGFloat = 56
        static let buttonHeight: CGFloat = 56
        static let authHeaderTopOffset: CGFloat = 120
        static let avatar: CGFloat = 120
        static let swatchTap: CGFloat = 48
        static let swatchInner: CGFloat = 36
        static let dividerThickness: CGFloat = 1
    }

    enum Opacity {
        static let disabled: CGFloat = 0.45
        static let pressed: CGFloat = 0.85
        static let appleDisabled: CGFloat = 0.5
    }
}
