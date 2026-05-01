import SwiftUI

/// Radial blob anchored above the top edge of the screen. Mirrors the
/// React Native `RadialBlob` with the `topAnchoredWide` geometry preset:
/// horizontal center is half-width, vertical center sits just above the
/// top edge, and the ellipse uses width-relative radii so side caps fade
/// off-screen.
///
/// Renders full-screen and ignores hit-testing so it never intercepts
/// taps from form controls layered on top.
struct AuthGradient: View {
    /// Center Y measured from the top of the screen. Negative places the
    /// center above the visible viewport.
    var verticalCenterFromTop: CGFloat = -135

    /// Horizontal radius as a fraction of screen width. RN preset uses
    /// `1.6` so the side caps fade off-screen.
    var horizontalRadiusFactor: CGFloat = 1.6

    /// Vertical radius as a fraction of screen WIDTH (not height). RN
    /// preset uses `0.95`, producing a wide ellipse with aspect ≈ 0.59.
    var verticalRadiusFactor: CGFloat = 0.95

    /// Gradient stops. Defaults to the auth purple → blue → transparent.
    var stops: [Gradient.Stop] = Gradients.authPrimaryStops

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let rx = w * horizontalRadiusFactor
            let ry = w * verticalRadiusFactor
            let aspect = rx > 0 ? ry / rx : 1
            let cx = w / 2
            let cy = verticalCenterFromTop

            // SwiftUI RadialGradient is circular only; render a square
            // canvas with a circular gradient and squash via scaleEffect
            // to get an ellipse, matching the RN Skia transform.
            Rectangle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: stops),
                        center: .center,
                        startRadius: 0,
                        endRadius: rx
                    )
                )
                .frame(width: rx * 2, height: rx * 2)
                .scaleEffect(x: 1, y: aspect, anchor: .center)
                .position(x: cx, y: cy)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        AppColors.surface.ignoresSafeArea()
        AuthGradient()
    }
}
