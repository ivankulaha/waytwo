import Foundation

struct ProfileReducer {
    struct State {
        var name = ""
        var email = ""
        var avatarLocalPath: String?
    }

    enum Action {
        case setName(String)
        case setEmail(String)
        case setAvatarLocalPath(String?)
    }

    static func reduce(state: inout State, action: Action) {
        switch action {
        case let .setName(value):
            state.name = value
        case let .setEmail(value):
            state.email = value
        case let .setAvatarLocalPath(path):
            state.avatarLocalPath = path
        }
    }
}
