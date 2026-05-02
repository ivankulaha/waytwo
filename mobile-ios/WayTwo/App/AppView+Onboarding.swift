import SwiftUI

extension AppView {
    func saveOnboardingYouStep() {
        let patch = ProfilePatch(
            displayName: state.onboarding.name,
            gender: state.onboarding.gender,
            dateOfBirth: state.onboarding.dateOfBirth
        )
        container.database.upsertProfileFields(patch)
    }

    func completeOnboarding() async {
        let token = container.keychain.loadSession()?.accessToken
        await container.profileSync.pushCompleteOnboarding(accessToken: token)
        state.hasCompletedOnboarding = true
    }
}
