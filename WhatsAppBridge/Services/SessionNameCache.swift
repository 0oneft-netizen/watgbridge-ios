import Foundation

@MainActor
final class SessionNameCache {
    static let shared =
        SessionNameCache()

    private var names:
        [String: String] =
            [:]

    func set(
        accountID: String,
        name: String
    ) {
        names[accountID] =
            name
    }

    func name(
        accountID: String
    ) -> String? {
        names[accountID]
    }

    func removeAll() {
        names.removeAll()
    }
}
