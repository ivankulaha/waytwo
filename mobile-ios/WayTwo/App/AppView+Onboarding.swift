import SwiftUI

extension AppView {
    func saveOnboardingYouStep() {
        let patch = ProfilePatch(
            displayName: state.onboarding.name,
            gender: state.onboarding.gender,
            dateOfBirth: state.onboarding.dateOfBirth
        )
        container.logger.info("onboarding.you.save", metadata: ["op": "enqueue"])
        container.profileSync.pushProfile(patch: patch)
        state.onboarding.step = .look
        Task { await container.syncCoordinator.sessionBecameActive() }
    }

    func completeOnboarding() {
        container.logger.info("onboarding.complete", metadata: ["op": "enqueue"])
        container.profileSync.enqueueCompleteOnboarding()
        container.database.markOnboardingCompleted()
        state.hasCompletedOnboarding = true
        Task { await container.syncCoordinator.sessionBecameActive() }
    }
}
