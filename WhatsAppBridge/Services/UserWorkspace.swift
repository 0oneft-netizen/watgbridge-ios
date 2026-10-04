import Foundation

// Routing contains a public workspace ID, never a password or access token.
enum UserWorkspace {
    static let serverURL = URL(string: "https://5jjltkwg.tail256e07.ts.net")!
    private static let mutex = NSLock()
    private static var identifier = "signed-out"
    static var id: String { mutex.lock(); defer { mutex.unlock() }; return identifier }
    static func select(_ id: String?) { mutex.lock(); identifier = id ?? "signed-out"; mutex.unlock() }
    static var baseURL: URL { serverURL.appendingPathComponent("u").appendingPathComponent(id) }
    static var defaults: UserDefaults {
        if id == "owner" { return .standard }
        return UserDefaults(suiteName: "watgbridge.user." + id)!
    }
    static func ownsNotification(_ info: [AnyHashable: Any]) -> Bool {
        guard id != "signed-out" else { return false }
        return ((info["app_user_id"] as? String) ?? "owner") == id
    }
}
