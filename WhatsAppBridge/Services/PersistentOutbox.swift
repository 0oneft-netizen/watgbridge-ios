import Foundation

struct OutboxTextMessage:
    Identifiable,
    Codable,
    Equatable {

    let id: UUID
    let accountID: String
    let chatJID: String
    let text: String
    let createdAt: Date
    var attempts: Int
}

@MainActor
final class PersistentOutbox:
    ObservableObject {

    static let shared =
        PersistentOutbox()

    @Published
    private(set)
    var items: [OutboxTextMessage] = []

    private let defaults =
        UserDefaults.standard

    private let storageKey =
        "persistent.outbox.v1"

    private init() {
        restore()
    }

    func enqueue(
        accountID: String,
        chatJID: String,
        text: String
    ) {
        let clean =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !clean.isEmpty else {
            return
        }

        let duplicate =
            items.contains {
                $0.accountID == accountID &&
                $0.chatJID == chatJID &&
                $0.text == clean
            }

        guard !duplicate else {
            return
        }

        items.append(
            OutboxTextMessage(
                id: UUID(),
                accountID: accountID,
                chatJID: chatJID,
                text: clean,
                createdAt: Date(),
                attempts: 0
            )
        )

        persist()
    }

    func markAttempt(
        id: UUID
    ) {
        guard
            let index =
                items.firstIndex(
                    where: {
                        $0.id == id
                    }
                )
        else {
            return
        }

        items[index].attempts += 1
        persist()
    }

    func remove(
        id: UUID
    ) {
        items.removeAll {
            $0.id == id
        }

        persist()
    }

    func messages(
        accountID: String,
        chatJID: String
    ) -> [OutboxTextMessage] {
        items
            .filter {
                $0.accountID == accountID &&
                $0.chatJID == chatJID
            }
            .sorted {
                $0.createdAt < $1.createdAt
            }
    }

    private func persist() {
        guard
            let data =
                try? JSONEncoder()
                    .encode(items)
        else {
            return
        }

        defaults.set(
            data,
            forKey: storageKey
        )
    }

    private func restore() {
        guard
            let data =
                defaults.data(
                    forKey: storageKey
                ),
            let decoded =
                try? JSONDecoder()
                    .decode(
                        [OutboxTextMessage].self,
                        from: data
                    )
        else {
            return
        }

        items = decoded
    }
}
