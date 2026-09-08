import PhotosUI
import SwiftUI
import UIKit

private struct AvatarCropPayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct OnboardingLookView: View {
    @Binding var state: OnboardingReducer.State
    var isOnline: Bool = true
    let onFinish: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var cropPayload: AvatarCropPayload?
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

                    PrimaryButton(
                        titleKey: "onboarding.look.finish",
                        isLoading: state.isLoading,
                        isDisabled: !isOnline,
                        action: onFinish
                    )
                    .frame(width: contentWidth)
                    if let errorKey = state.errorKey {
                        Text(LocalizedStringKey(errorKey))
                            .foregroundStyle(AppColors.error)
                            .padding(.top, Tokens.Spacing.md)
                    }

                    Spacer().frame(height: Tokens.Spacing.x3l)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, Tokens.Spacing.xl)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: state.colorId)
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, newItem in
            guard let newItem else { return }
            Task { await loadLibraryImageForCrop(newItem) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(
                isPresented: $showCamera,
                onPick: { cropPayload = AvatarCropPayload(image: $0) },
                onCancel: {}
            )
        }
        .fullScreenCover(item: $cropPayload) { payload in
            AvatarCropView(
                image: payload.image,
                onConfirm: { image in
                    saveConfirmedAvatar(image)
                    cropPayload = nil
                },
                onCancel: { cropPayload = nil }
            )
        }
    }

    private var glowLayer: some View {
        GeometryReader { proxy in
            let r = Tokens.Size.glowRadius
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
        Menu {
            photoSourceMenuItems
        } label: {
            ProfileAvatarView(
                colorId: state.colorId,
                photo: profilePhoto,
                displayName: state.name,
                showsName: false
            )
        }
        .accessibilityLabel(LocalizedStringKey("onboarding.look.changePhoto"))
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).midY
        } action: { midY in
            avatarGlobalMidY = midY
        }
    }

    private var changePhotoControl: some View {
        Menu {
            photoSourceMenuItems
        } label: {
            Text("onboarding.look.changePhoto")
                .font(.system(size: Tokens.FontSize.xl, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var photoSourceMenuItems: some View {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Button {
                showCamera = true
            } label: {
                Label("crop.sourceCamera", systemImage: "camera")
            }
        }
        Button {
            showPhotoPicker = true
        } label: {
            Label("crop.sourceLibrary", systemImage: "photo.on.rectangle")
        }
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

    private func loadLibraryImageForCrop(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                logger.warn("onboarding.look.photoImportEmpty")
                await MainActor.run { pickerItem = nil }
                return
            }
            guard let uiImage = UIImage(data: data) else {
                logger.warn("onboarding.look.photoImportEmpty")
                await MainActor.run { pickerItem = nil }
                return
            }
            await MainActor.run {
                pickerItem = nil
                showPhotoPicker = false
                cropPayload = AvatarCropPayload(image: uiImage)
            }
        } catch {
            logger.warn("onboarding.look.photoImportFailed", metadata: ["reason": String(describing: error)])
            await MainActor.run { pickerItem = nil }
        }
    }

    private func saveConfirmedAvatar(_ image: UIImage) {
        do {
            let url = try AvatarPhotoFileStore.saveJPEG(image)
            state.photoLocalPath = url.path
            logger.info("onboarding.look.avatarCropped", metadata: ["op": "avatar_crop", "status": "saved"])
        } catch {
            logger.warn("onboarding.look.photoSaveFailed", metadata: ["reason": String(describing: error)])
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
