import SwiftUI
import UIKit

enum AppColors {
    private static func uiRGB(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: alpha)
    }

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    static let surface = adaptive(light: .white, dark: .black)
    static let surfaceElevated = adaptive(light: uiRGB(242, 242, 247), dark: uiRGB(28, 28, 30))
    static let homeBackground = adaptive(light: uiRGB(246, 240, 255), dark: .black)
    static let settingsBackground = adaptive(light: uiRGB(242, 242, 247), dark: .black)

    static let textPrimary = adaptive(light: uiRGB(9, 9, 11), dark: .white)
    static let textSecondary = adaptive(light: uiRGB(82, 82, 91), dark: uiRGB(209, 214, 255))
    static let textPlaceholder = adaptive(light: uiRGB(124, 124, 124), dark: uiRGB(161, 161, 161))

    static let separator = adaptive(light: uiRGB(196, 196, 204), dark: uiRGB(75, 75, 96))

    static let inputBackground = adaptive(light: .white, dark: .black)
    static let inputBorder = adaptive(light: uiRGB(196, 196, 204), dark: uiRGB(47, 47, 47))
    static let inputBorderFocused = adaptive(light: .black, dark: .white)

    static let buttonBackground = Color.white
    static let buttonText = Color.black
    static let buttonPressedBackground = adaptive(light: uiRGB(240, 240, 240), dark: uiRGB(224, 224, 224))
    static let buttonDisabledBackground = adaptive(light: uiRGB(228, 228, 231), dark: uiRGB(38, 38, 38))
    static let buttonDisabledText = adaptive(light: uiRGB(161, 161, 170), dark: uiRGB(115, 115, 115))

    static let error = adaptive(light: uiRGB(220, 38, 38), dark: uiRGB(248, 113, 113))

    static let glassBg = adaptive(light: uiRGB(0, 0, 0, alpha: 0.08), dark: uiRGB(255, 255, 255, alpha: 0.12))
    static let glassBorder = adaptive(light: uiRGB(0, 0, 0, alpha: 0.15), dark: uiRGB(255, 255, 255, alpha: 0.22))

    static let profileFallback = Color(red: 107 / 255, green: 31 / 255, blue: 221 / 255)

    static let profileColorsOrdered: [(id: String, color: Color)] = [
        ("coral", rgb(235, 72, 40)),
        ("tangerine", rgb(244, 136, 29)),
        ("amber", rgb(253, 199, 84)),
        ("lemon", rgb(255, 255, 123)),
        ("leaf", rgb(71, 202, 23)),
        ("mint", rgb(61, 250, 180)),
        ("sky", rgb(56, 175, 255)),
        ("azure", rgb(0, 30, 255)),
        ("purple", rgb(107, 31, 221)),
        ("magenta", rgb(236, 62, 255)),
        ("rose", rgb(255, 43, 135)),
        ("crimson", rgb(225, 53, 56)),
    ]

    static let profilePalette: [String: Color] = {
        var map = Dictionary(uniqueKeysWithValues: profileColorsOrdered.map { ($0.id, $0.color) })
        map["blue"] = map["sky"]
        map["teal"] = map["mint"]
        map["green"] = map["leaf"]
        map["orange"] = map["tangerine"]
        map["pink"] = map["rose"]
        return map
    }()

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> Color {
        Color(red: r / 255, green: g / 255, blue: b / 255)
    }
}
