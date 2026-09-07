import Foundation


enum ProfileCompleteness {
    static func hasFinishedOnboarding(
        displayName: String?,
        gender: String?,
        onboardingCompletedAt: String?
    ) -> Bool {
        guard onboardingCompletedAt != nil else { return false }
        let trimmedName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty, let gender, !gender.isEmpty else { return false }
        return true
    }
}
