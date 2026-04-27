import SwiftUI

struct OnboardingYouView: View {
    @Binding var state: OnboardingReducer.State
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.xl) {
                TextField("onboarding.you.namePlaceholder", text: $state.name)
                    .padding(Tokens.Spacing.xl)
                    .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.lg).stroke(AppColors.inputBorder))
                Picker("onboarding.you.genderLabel", selection: $state.gender) {
                    Text("onboarding.you.genderMale").tag("male")
                    Text("onboarding.you.genderFemale").tag("female")
                    Text("onboarding.you.genderOther").tag("other")
                }
                .pickerStyle(.segmented)
                TextField("onboarding.you.dobPlaceholder", text: $state.dateOfBirth)
                    .padding(Tokens.Spacing.xl)
                    .overlay(RoundedRectangle(cornerRadius: Tokens.Radius.lg).stroke(AppColors.inputBorder))
                Button("onboarding.you.next", action: onNext)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                if let errorKey = state.errorKey {
                    Text(LocalizedStringKey(errorKey))
                        .foregroundStyle(AppColors.error)
                }
            }
            .padding(Tokens.Spacing.x3l)
        }
        .background(AppColors.surface.ignoresSafeArea())
        .navigationTitle("onboarding.you.title")
    }
}

#Preview {
    NavigationStack {
        OnboardingYouView(
            state: .constant(OnboardingReducer.State()),
            onNext: {}
        )
    }
}
