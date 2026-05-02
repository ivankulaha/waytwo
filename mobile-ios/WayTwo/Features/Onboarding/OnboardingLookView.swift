import PhotosUI
import SwiftUI
import UIKit

struct OnboardingLookView: View {
    @Binding var state: OnboardingReducer.State
    let onFinish: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var avatarGlobalMidY: CGFloat = 280

    private let logger = AppLogger()

    private var selectedProfileColor: Color {
        AppColors.profilePalette[state.colorId] ?? AppColors.profileFallback
    }

    private var profilePhoto: UIImage? {
        guard let path = state.photoLocalPath else { return nil }
        return UIImage(contentsOfFile: path)
    }

    var body: some View {
        ZStack {
            AppColors.surface.ignoresSafeArea()

            glowLayer

            GeometryReader { proxy in
                let horizontalPadding = Tokens.Spacing.xl * 2
                let contentWidth = min(Tokens.Size.contentWidth, max(0, proxy.size.width - horizontalPadding))

                VStack(spacing: 0) {
                    Spacer().frame(height: Tokens.FormScreen.Spacing.beforeHeaderWithNavBar)

                    FormScreenTitleText(titleKey: "onboarding.look.title")
                        .frame(width: contentWidth)

                    Spacer().frame(height: Tokens.Spacing.x3l)

                    VStack(spacing: Tokens.Spacing.lg) {
                        avatarButton
                            .frame(maxWidth: .infinity)
                        changePhotoControl
                    }
                    .frame(width: contentWidth)

                    Spacer().frame(height: Tokens.Spacing.x3l)

                    profileColorGlassPanel
                        .frame(width: contentWidth)

                    Spacer(minLength: Tokens.Spacing.xl)

                    PrimaryButton(titleKey: "onboarding.look.finish", action: onFinish)
                        .frame(width: contentWidth)

                    Spacer().frame(height: Tokens.Spacing.x3l)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, Tokens.Spacing.xl)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.4), value: state.colorId)
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await persistPickedPhoto(newItem) }
        }
    }

    private static let glowRadius: CGFloat = 240

    private var glowLayer: some View {
        GeometryReader { proxy in
            let r = Self.glowRadius
            Rectangle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: Gradients.profileGlowStops(color: selectedProfileColor)),
                        center: .center,
                        startRadius: 0,
                        endRadius: r
                    )
                )
                .frame(width: r * 2, height: r * 2)
                .position(x: proxy.size.width / 2, y: avatarGlobalMidY - proxy.frame(in: .global).minY)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var avatarButton: some View {
        Button {
            showPhotoPicker = true
        } label: {
            avatarContent
                .frame(width: Tokens.Size.avatar, height: Tokens.Size.avatar)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LocalizedStringKey("onboarding.look.changePhoto"))
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).midY
        } action: { midY in
            avatarGlobalMidY = midY
        }
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let image = profilePhoto {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle()
                    .fill(selectedProfileColor.opacity(0.4))
                Image(systemName: "person.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.85))
            }
        }
    }

    private var changePhotoControl: some View {
        Button {
            showPhotoPicker = true
        } label: {
            Text("onboarding.look.changePhoto")
                .font(.system(size: Tokens.FontSize.xl, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var profileColorGlassPanel: some View {
        let row1 = Array(AppColors.profileColorsOrdered.prefix(6))
        let row2 = Array(AppColors.profileColorsOrdered.suffix(6))

        return VStack(alignment: .leading, spacing: Tokens.Spacing.x3l) {
            Text("onboarding.look.colorLabel")
                .font(.system(size: Tokens.FontSize.sm, weight: .medium))
                .foregroundStyle(AppColors.textPlaceholder)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: Tokens.Spacing.swatchRowGap) {
                profileColorRow(items: row1)
                profileColorRow(items: row2)
            }
        }
        .padding(Tokens.Spacing.xl)
        .modifier(GlassPanelBackground(cornerRadius: Tokens.Radius.glassPanel))
    }

    private func profileColorRow(items: [(id: String, color: Color)]) -> some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.id) { item in
                ProfileColorSwatchView(
                    color: item.color,
                    isSelected: state.colorId == item.id
                ) {
                    state.colorId = item.id
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Photo import

    private func persistPickedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                logger.warn("onboarding.look.photoImportEmpty")
                return
            }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: false)
                .appendingPathExtension("jpg")
            try data.write(to: url, options: .atomic)
            await MainActor.run {
                state.photoLocalPath = url.path
            }
        } catch {
            logger.warn("onboarding.look.photoImportFailed", metadata: ["reason": String(describing: error)])
        }
    }
}

private struct ProfileColorSwatchView: View {
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: Tokens.Size.swatchTap, height: Tokens.Size.swatchTap)
                    .overlay {
                        Circle()
                            .strokeBorder(isSelected ? color : Color.clear, lineWidth: 2)
                    }

                Circle()
                    .fill(color.opacity(0.9))
                    .frame(width: Tokens.Size.swatchInner, height: Tokens.Size.swatchInner)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct GlassPanelBackground: ViewModifier {
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.12), location: 0),
                                    .init(color: Color.clear, location: 0.5),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .allowsHitTesting(false)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppColors.glassBorder, lineWidth: 1)
                        .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                OnboardingLookView(
                    state: .constant(OnboardingReducer.State()),
                    onFinish: {}
                )
                .navigationTitle("onboarding.look.title")
                .hidesNavigationBarTitle()
            }
    }
}
