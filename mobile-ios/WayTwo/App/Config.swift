import Foundation

enum Config {
    private static func value(for key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }

    static var supabaseURL: URL {
        URL(string: value(for: "SUPABASE_URL")) ?? URL(string: "https://supabase_url.notfound.com")!
    }

    static var supabaseAnonKey: String {
        let key = value(for: "SUPABASE_ANON_KEY")
        return key.isEmpty ? "public-anon-key-placeholder" : key
    }

    static var apiURL: URL {
        URL(string: value(for: "API_URL")) ?? URL(string: "https://api_url.notfound.com")!
    }
}
