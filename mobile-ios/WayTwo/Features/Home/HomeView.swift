import SwiftUI
import UIKit

struct HomeView: View {
    @Binding var state: HomeReducer.State
    private let avatarVerticalOffset: CGFloat = 273

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    AppColors.homeBackground
                        .ignoresSafeArea()

                    inviteGlowLayer(proxy: proxy)

                    ProfileAvatarView(
                        colorId: state.colorId,
                        photo: profilePhoto,
                        displayName: state.displayName
                    )
                    .position(
                        x: proxy.size.width / 2,
                        // Figma home screen avatar center: 874 / 2 - 273 (`148:2200`, `326:5945`).
                        y: (proxy.size.height / 2) - avatarVerticalOffset
                    )

                    invitePartnerSection
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
            }
            .ignoresSafeArea()
            .navigationTitle(String(localized: "tabs.home"))
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var selectedProfileColor: Color {
        AppColors.profilePalette[state.colorId] ?? AppColors.profileFallback
    }

    private var profilePhoto: UIImage? {
        guard let path = state.photoPath else { return nil }
        return UIImage(contentsOfFile: path)
    }

    private var invitePartnerSection: some View {
        Button {
            state.invitePending = true
        } label: {
            VStack(spacing: Tokens.Spacing.lg) {
                inviteCircle
                Text("home.invitePartner")
                    .font(.system(size: Tokens.FontSize.xl, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .buttonStyle(ScaleDownButtonStyle())
    }

    private var inviteCircle: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
            Circle()
                .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                .allowsHitTesting(false)
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: Tokens.FontSize.avatarInitial, weight: .semibold))
                .foregroundStyle(Color.white)
        }
        .frame(width: Tokens.Size.avatar, height: Tokens.Size.avatar)
    }

    private func inviteGlowLayer(proxy: GeometryProxy) -> some View {
        let glowRadius = Tokens.Size.glowRadius

        return Rectangle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: Gradients.profileGlowStops(color: selectedProfileColor)),
                    center: .center,
                    startRadius: 0,
                    endRadius: glowRadius
                )
            )
            .frame(width: glowRadius * 2, height: glowRadius * 2)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .allowsHitTesting(false)
    }
}

private struct ScaleDownButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    HomeView(
        state: .constant({ var s = HomeReducer.State(); s.displayName = "Alex"; return s }())
    )
}
