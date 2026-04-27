import Foundation

struct OnboardingReducer {
    struct State {
        enum Step {
            case intro
            case you
            case look
        }

        var step: Step = .intro
        var name = ""
        var gender = ""
        var dateOfBirth = ""
        var colorId = "purple"
        var photoLocalPath: String?
        var isLoading = false
        var errorKey: String?
    }
}
