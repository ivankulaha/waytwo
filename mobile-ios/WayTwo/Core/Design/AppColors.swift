import SwiftUI

enum AppColors {
    static let surface = Color.black
    static let surfaceElevated = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.75)
    static let textPlaceholder = Color(red: 0.63, green: 0.63, blue: 0.63)
    static let separator = Color.white.opacity(0.2)
    static let inputBackground = Color.black
    static let inputBorder = Color.white.opacity(0.3)
    static let inputBorderFocused = Color.white
    static let buttonBackground = Color.white
    static let buttonText = Color.black
    static let buttonPressedBackground = Color(red: 0.88, green: 0.88, blue: 0.88)
    static let buttonDisabledBackground = Color(red: 0x26 / 255, green: 0x26 / 255, blue: 0x26 / 255)
    static let buttonDisabledText = Color(red: 0x73 / 255, green: 0x73 / 255, blue: 0x73 / 255)
    static let error = Color(red: 1.0, green: 0.36, blue: 0.36)
    static let homeBackground = Color.black
    static let settingsBackground = Color.black
    static let profileFallback = Color(red: 107 / 255, green: 31 / 255, blue: 221 / 255)

    static let onboardingGlassStroke = Color.white.opacity(0.22)

    /// Figma `124:6297`, `326:6080`.
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

    /// Lookup for glow, avatar ring, and persisted `color_id`. Includes legacy keys from the previous six-swatch palette.
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
