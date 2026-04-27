import SwiftUI
import PhotosUI

struct OnboardingLookView: View {
    @Binding var state: OnboardingReducer.State
    let onFinish: () -> Void
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            Text("onboarding.look.title")
                .font(.title2)
                .foregroundStyle(AppColors.textPrimary)
            Text("onboarding.look.colorLabel")
                .foregroundStyle(AppColors.textSecondary)
            HStack(spacing: Tokens.Spacing.md) {
                ForEach(Array(AppColors.profilePalette.keys).sorted(), id: \.self) { key in
                    Circle()
                        .fill(AppColors.profilePalette[key] ?? AppColors.profileFallback)
                        .frame(width: Tokens.Size.swatchInner, height: Tokens.Size.swatchInner)
                        .padding(6)
                        .overlay(Circle().stroke(state.colorId == key ? AppColors.profilePalette[key] ?? .white : .clear, lineWidth: 2))
                        .onTapGesture { state.colorId = key }
                }
            }
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("onboarding.look.changePhoto")
            }
            Button("onboarding.look.finish", action: onFinish)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(Tokens.Spacing.x3l)
        .background(AppColors.surface.ignoresSafeArea())
        .navigationTitle("onboarding.look.title")
    }
}

#Preview {
    NavigationStack {
        OnboardingLookView(
            state: .constant(OnboardingReducer.State()),
            onFinish: {}
        )
    }
}
