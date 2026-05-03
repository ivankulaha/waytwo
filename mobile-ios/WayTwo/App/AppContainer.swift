import Foundation

struct AppContainer {
    let logger: AppLogger
    let keychain: KeychainClient
    let database: DatabaseClient
    let supabase: SupabaseClient
    let api: APIClient
    let profileSync: ProfileSync
    let outbox: Outbox
    let networkMonitor: NetworkMonitor
    let syncCoordinator: SyncCoordinator

    static let live: AppContainer = {
        let logger = AppLogger()
        let keychain = KeychainClient()
        let database = DatabaseClient(logger: logger)
        let api = APIClient(baseURL: Config.apiURL, logger: logger)
        let supabase = SupabaseClient(baseURL: Config.supabaseURL, publishableKey: Config.supabasePublishableKey, logger: logger)
        let networkMonitor = NetworkMonitor(logger: logger)
        let outbox = Outbox(database: database, apiClient: api, logger: logger)
        let profileSync = ProfileSync(database: database, apiClient: api, outbox: outbox, logger: logger)
        let syncCoordinator = SyncCoordinator(
            outbox: outbox,
            profileSync: profileSync,
            keychain: keychain,
            networkMonitor: networkMonitor,
            logger: logger
        )

        return AppContainer(
            logger: logger,
            keychain: keychain,
            database: database,
            supabase: supabase,
            api: api,
            profileSync: profileSync,
            outbox: outbox,
            networkMonitor: networkMonitor,
            syncCoordinator: syncCoordinator
        )
    }()
}
