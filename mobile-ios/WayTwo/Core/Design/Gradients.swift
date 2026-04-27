import SwiftUI

enum Gradients {
    /// Auth radial blob stops (dark theme). Mirrors React Native
    /// `RadialBlobPalette.authPrimary.dark`: `#B566FF` → `#506DF1` → transparent.
    static let authPrimaryStops: [Gradient.Stop] = [
        .init(color: Color(red: 0.71, green: 0.4, blue: 1.0), location: 0.0),
        .init(color: Color(red: 0.31, green: 0.43, blue: 0.95), location: 0.55),
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
}
