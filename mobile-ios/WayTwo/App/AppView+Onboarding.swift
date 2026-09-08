import SwiftUI

extension AppView {
    func saveOnboardingYouStep() async {
        if container.networkMonitor.status == .offline {
            state.onboarding.errorKey = "error.offline"
            return
        }
        state.onboarding.errorKey = nil
        state.onboarding.isLoading = true
        defer { state.onboarding.isLoading = false }

        let patch = ProfilePatch(
            displayName: state.onboarding.name,
            gender: state.onboarding.gender,
            dateOfBirth: state.onboarding.dateOfBirth
        )
        container.logger.info("onboarding.you.save", metadata: ["op": "start"])
        switch await container.profileSync.pushProfile(patch: patch) {
        case .success:
            state.onboarding.step = .look
        case let .failure(error):
            state.onboarding.errorKey = error.localizationKey
        }
    }

    func completeOnboarding() async {
        if container.networkMonitor.status == .offline {
            state.onboarding.errorKey = "error.offline"
            return
        }
        state.onboarding.errorKey = nil
        state.onboarding.isLoading = true
        defer { state.onboarding.isLoading = false }

        let look = ProfilePatch(
            colorId: state.onboarding.colorId,
            photoPath: state.onboarding.photoLocalPath
        )
        container.logger.info("onboarding.complete", metadata: ["op": "start"])
        switch await container.profileSync.completeOnboarding(look: look) {
        case .success:
            state.hasCompletedOnboarding = true
        case let .failure(error):
            state.onboarding.errorKey = error.localizationKey
        }
    }
}
