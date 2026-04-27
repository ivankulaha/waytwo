import Foundation

struct AuthReducer {
    struct State {
        enum Flow {
            case email
            case password
            case signup
            case forgot
            case emailSent
            case newPassword
        }

        var flow: Flow = .email
        var email = ""
        var password = ""
        var newPassword = ""
        var appleNonce = ""
        var isLoading = false
        var errorKey: String?
    }
}
