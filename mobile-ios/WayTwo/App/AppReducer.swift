import Foundation

struct AppReducer {
    struct State {
        var isAuthenticated = false
        var profileRoutingReady = false
        var hasCompletedOnboarding = false
        var selectedTab: Tab = .home
        var auth = AuthReducer.State()
        var onboarding = OnboardingReducer.State()
        var home = HomeReducer.State()
        var settings = SettingsReducer.State()
        var launchErrorKey: String?
    }

    enum Tab: Hashable {
        case home
        case settings
    }

    enum Action {
        case appStarted
        case setAuthenticated(Bool)
        case setOnboardingCompleted(Bool)
        case selectTab(Tab)
        case setLaunchError(String?)
    }

    static func reduce(state: inout State, action: Action) {
        switch action {
        case .appStarted:
            break
        case let .setAuthenticated(value):
            state.isAuthenticated = value
        case let .setOnboardingCompleted(value):
            state.hasCompletedOnboarding = value
        case let .selectTab(tab):
            state.selectedTab = tab
        case let .setLaunchError(key):
            state.launchErrorKey = key
        }
    }
}
