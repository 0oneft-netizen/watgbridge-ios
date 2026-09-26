import Foundation

@MainActor
final class StarredMessageStore:
    ObservableObject {

    static let shared =
        StarredMessageStore()

    @Published
    private(set)
    var keys = Set<String>()

    private let defaults =
        UserDefaults.standard

    private let storageKey =
        "starred.message.keys"

    private init() {
        keys = Set(
            defaults.stringArray(
                forKey: storageKey
            ) ?? []
        )
    }

    private func key(
        _ message: Message
    ) -> String {
        let account =
            message.accountID
            ?? "default"

        return account
            + "|"
            + message.messageID
    }

    func contains(
        _ message: Message
    ) -> Bool {
        keys.contains(
            key(message)
        )
    }

    func toggle(
        _ message: Message
    ) {
        let value = key(message)

        if keys.contains(value) {
            keys.remove(value)
        } else {
            keys.insert(value)
        }

        defaults.set(
            Array(keys),
            forKey: storageKey
        )
    }
}
