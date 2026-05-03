import SwiftUI
import UIKit

enum AvatarPhotoFileStore {
    static func saveJPEG(_ image: UIImage) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("jpg")
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}

struct AvatarCropView: View {
    let image: UIImage
    let onConfirm: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var steadyScale: CGFloat = 1
    @GestureState private var pinchMag: CGFloat = 1
    @State private var steadyOffset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var layoutSize: CGSize = .zero

    private let logger = AppLogger()

    private var effectiveScale: CGFloat { steadyScale * pinchMag }

    private var effectiveOffset: CGSize {
        CGSize(
            width: steadyOffset.width + dragTranslation.width,
            height: steadyOffset.height + dragTranslation.height
        )
    }

    var body: some View {
        let D = Tokens.Size.cropCircle
        let pinchGesture = MagnificationGesture()
            .updating($pinchMag) { value, state, _ in
                state = value
            }
            .onEnded { value in
                let next = steadyScale * value
                steadyScale = min(max(next, minPinchScale), maxPinchScale)
                steadyOffset = clampedOffset(steadyOffset, userScale: steadyScale)
            }

        let dragGesture = DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let proposed = CGSize(
                    width: steadyOffset.width + value.translation.width,
                    height: steadyOffset.height + value.translation.height
                )
                steadyOffset = clampedOffset(proposed, userScale: steadyScale)
            }

        ZStack {
            AppColors.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    let cw = geo.size.width
                    let ch = geo.size.height
                    let imgW = image.size.width
                    let imgH = image.size.height
                    let cx = cw / 2
                    let cy = ch / 2
                    let sFill = max(D / imgW, D / imgH)
                    let dw = imgW * sFill * effectiveScale
                    let dh = imgH * sFill * effectiveScale
                    let mx = cx + effectiveOffset.width
                    let my = cy + effectiveOffset.height

                    Color.clear
                        .onAppear {
                            layoutSize = geo.size
                        }
                        .onChange(of: geo.size) { _, newSize in
                            layoutSize = newSize
                        }

                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: dw, height: dh)
                            .position(x: mx, y: my)
                            .simultaneousGesture(pinchGesture)
                            .simultaneousGesture(dragGesture)

                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .mask {
                                Rectangle()
                                    .overlay {
                                        Circle()
                                            .frame(width: D, height: D)
                                            .blendMode(.destinationOut)
                                    }
                            }
                            .allowsHitTesting(false)

                        Circle()
                            .strokeBorder(AppColors.textPrimary.opacity(0.35), lineWidth: 1)
                            .frame(width: D, height: D)
                            .position(x: cx, y: cy)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxHeight: .infinity)

                bottomBar
            }
        }
    }

    private var minPinchScale: CGFloat { 1 }
    private var maxPinchScale: CGFloat { 5 }

    private var bottomBar: some View {
        HStack(spacing: Tokens.Spacing.xl) {
            Button(role: .cancel) {
                onCancel()
            } label: {
                Text("common.cancel")
                    .font(.system(size: Tokens.FontSize.lg, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Tokens.Size.buttonHeight)
            }
            .buttonStyle(.plain)

            Button {
                confirmCrop()
            } label: {
                Text("crop.confirm")
                    .font(.system(size: Tokens.FontSize.lg, weight: .semibold))
                    .foregroundStyle(AppColors.buttonText)
                    .frame(maxWidth: .infinity)
                    .frame(height: Tokens.Size.buttonHeight)
                    .background(AppColors.buttonBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Tokens.Spacing.xl)
        .padding(.vertical, Tokens.Spacing.lg)
        .background(AppColors.surface.opacity(0.95))
    }

    private func clampedOffset(_ offset: CGSize, userScale: CGFloat) -> CGSize {
        let D = Tokens.Size.cropCircle
        let imgW = image.size.width
        let imgH = image.size.height
        let sFill = max(D / imgW, D / imgH)
        let dw = imgW * sFill * userScale
        let dh = imgH * sFill * userScale
        let minOx = D / 2 - dw / 2
        let maxOx = dw / 2 - D / 2
        let minOy = D / 2 - dh / 2
        let maxOy = dh / 2 - D / 2
        return CGSize(
            width: min(max(offset.width, minOx), maxOx),
            height: min(max(offset.height, minOy), maxOy)
        )
    }

    private func confirmCrop() {
        let D = Tokens.Size.cropCircle
        let cw = layoutSize.width
        let ch = layoutSize.height
        guard cw > 1, ch > 1 else {
            logger.warn("avatarCrop.layoutNotReady")
            return
        }
        let ox = steadyOffset.width
        let oy = steadyOffset.height
        let imgW = image.size.width
        let imgH = image.size.height
        let sFill = max(D / imgW, D / imgH)
        let dw = imgW * sFill * steadyScale
        let dh = imgH * sFill * steadyScale

        let cropped = image.croppedAvatarCircle(
            cropDiameter: D,
            offset: CGSize(width: ox, height: oy),
            displayedSize: CGSize(width: dw, height: dh)
        )
        onConfirm(cropped)
    }
}

private extension UIImage {
    func croppedAvatarCircle(
        cropDiameter: CGFloat,
        offset: CGSize,
        displayedSize: CGSize
    ) -> UIImage {
        let D = cropDiameter
        let dw = displayedSize.width
        let dh = displayedSize.height
        let drawRect = CGRect(
            x: offset.width - dw / 2 + D / 2,
            y: offset.height - dh / 2 + D / 2,
            width: dw,
            height: dh
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: D, height: D), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.saveGState()
            let clip = CGPath(
                ellipseIn: CGRect(x: 0, y: 0, width: D, height: D),
                transform: nil
            )
            cg.addPath(clip)
            cg.clip()
            draw(in: drawRect)
            cg.restoreGState()
        }
    }
}
