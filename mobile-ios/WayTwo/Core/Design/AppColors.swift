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
    static let profileFallback = Color(red: 0.55, green: 0.36, blue: 0.96)

    static let profilePalette: [String: Color] = [
        "purple": Color(red: 0.55, green: 0.36, blue: 0.96),
        "blue": Color(red: 0.35, green: 0.61, blue: 1.0),
        "teal": Color(red: 0.29, green: 0.76, blue: 0.73),
        "green": Color(red: 0.45, green: 0.83, blue: 0.35),
        "orange": Color(red: 0.97, green: 0.63, blue: 0.27),
        "pink": Color(red: 0.98, green: 0.4, blue: 0.66),
    ]
}
