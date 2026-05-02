import SwiftUI

enum Gradients {
    /// Auth radial blob stops (dark theme). Uses extra alpha stops so the
    /// purple-to-blue glow does not reveal a circular contour in SwiftUI.
    static let authPrimaryStops: [Gradient.Stop] = [
        .init(color: Color(red: 0.71, green: 0.4, blue: 1.0), location: 0.0),
        .init(color: Color(red: 0.61, green: 0.42, blue: 0.98).opacity(0.78), location: 0.34),
        .init(color: Color(red: 0.31, green: 0.43, blue: 0.95).opacity(0.38), location: 0.68),
        .init(color: Color(red: 0.31, green: 0.43, blue: 0.95).opacity(0), location: 1.0),
    ]

    static func homeGlow(color: Color) -> RadialGradient {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: color.opacity(0.4), location: 0.0),
                .init(color: color.opacity(0.2), location: 0.45),
                .init(color: color.opacity(0.04), location: 0.75),
                .init(color: color.opacity(0), location: 1.0),
            ]),
            center: .center,
            startRadius: 0,
            endRadius: 240
        )
    }

    /// Brighter stops than `homeGlow` so tint reaches the profile color panel below the avatar.
    static func profileGlowStops(color: Color) -> [Gradient.Stop] {
        [
            .init(color: color.opacity(0.65), location: 0.0),
            .init(color: color.opacity(0.45), location: 0.35),
            .init(color: color.opacity(0.18), location: 0.65),
            .init(color: color.opacity(0.0),  location: 1.0),
        ]
    }
}
