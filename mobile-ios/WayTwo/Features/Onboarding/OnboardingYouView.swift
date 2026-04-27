import SwiftUI

struct OnboardingYouView: View {
    @Binding var state: OnboardingReducer.State
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.xl) {
                AppTextField(
                    placeholder: "onboarding.you.namePlaceholder",
                    text: $state.name
                )
                Picker("onboarding.you.genderLabel", selection: $state.gender) {
                    Text("onboarding.you.genderMale").tag("male")
                    Text("onboarding.you.genderFemale").tag("female")
                    Text("onboarding.you.genderOther").tag("other")
                }
                .pickerStyle(.segmented)
                AppTextField(
                    placeholder: "onboarding.you.dobPlaceholder",
                    text: $state.dateOfBirth
                )
                PrimaryButton(titleKey: "onboarding.you.next", action: onNext)
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
