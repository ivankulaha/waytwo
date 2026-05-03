import PhotosUI
import SwiftUI
import UIKit

private struct AvatarCropPayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ProfileEditView: View {
    @Binding var state: ProfileReducer.State

    @State private var pickerItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var cropPayload: AvatarCropPayload?

    private let logger = AppLogger()

    private var profilePhoto: UIImage? {
        guard let path = state.avatarLocalPath else { return nil }
        return UIImage(contentsOfFile: path)
    }

    var body: some View {
        Form {
            Section {
                Menu {
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
                } label: {
                    profileAvatarContent
                        .frame(width: Tokens.Size.avatar, height: Tokens.Size.avatar)
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, Tokens.Spacing.lg)
            }
            .listRowBackground(Color.clear)

            TextField("onboarding.you.nameLabel", text: $state.name)

            TextField("auth.emailLabel", text: $state.email)
                .textInputAutocapitalization(.never)
        }
        .navigationTitle("profile.edit")
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

    @ViewBuilder
    private var profileAvatarContent: some View {
        if let image = profilePhoto {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle()
                    .fill(AppColors.profileFallback.opacity(0.35))
                Image(systemName: "person.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary.opacity(0.85))
            }
        }
    }

    private func loadLibraryImageForCrop(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                logger.warn("profile.avatar.photoImportEmpty")
                await MainActor.run { pickerItem = nil }
                return
            }
            guard let uiImage = UIImage(data: data) else {
                logger.warn("profile.avatar.photoImportEmpty")
                await MainActor.run { pickerItem = nil }
                return
            }
            await MainActor.run {
                pickerItem = nil
                showPhotoPicker = false
                cropPayload = AvatarCropPayload(image: uiImage)
            }
        } catch {
            logger.warn("profile.avatar.photoImportFailed", metadata: ["reason": String(describing: error)])
            await MainActor.run { pickerItem = nil }
        }
    }

    private func saveConfirmedAvatar(_ image: UIImage) {
        do {
            let url = try AvatarPhotoFileStore.saveJPEG(image)
            var next = state
            ProfileReducer.reduce(state: &next, action: .setAvatarLocalPath(url.path))
            state = next
            logger.info("profile.avatar.cropped", metadata: ["op": "avatar_crop", "status": "saved"])
        } catch {
            logger.warn("profile.avatar.photoSaveFailed", metadata: ["reason": String(describing: error)])
        }
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                ProfileEditView(
                    state: .constant({ var s = ProfileReducer.State(); s.name = "Alex"; s.email = "alex@example.com"; return s }())
                )
            }
    }
}
