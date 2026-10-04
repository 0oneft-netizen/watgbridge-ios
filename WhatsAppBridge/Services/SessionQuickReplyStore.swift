import Foundation

struct SessionQuickReply:
    Identifiable,
    Codable,
    Equatable {

    let id: UUID
    let accountID: String
    var shortcut: String
    var text: String
}

@MainActor
final class SessionQuickReplyStore:
    ObservableObject {

    static let shared =
        SessionQuickReplyStore()

    @Published
    private(set)
    var values:
        [SessionQuickReply] = []

    private var defaults: UserDefaults { UserWorkspace.defaults }

    private let key =
        "session.quick.replies.v1"

    private init() {
        restore()
    }

    func replies(
        accountID: String
    ) -> [SessionQuickReply] {
        values.filter {
            $0.accountID ==
                accountID
        }
    }

    func add(
        accountID: String,
        shortcut: String,
        text: String
    ) {
        let shortcut =
            shortcut
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let text =
            text
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard
            !shortcut.isEmpty,
            !text.isEmpty
        else {
            return
        }

        values.append(
            SessionQuickReply(
                id: UUID(),
                accountID:
                    accountID,
                shortcut:
                    shortcut,
                text:
                    text
            )
        )

        persist()
    }

    func remove(
        id: UUID
    ) {
        values.removeAll {
            $0.id == id
        }

        persist()
    }

    private func persist() {
        guard
            let data =
                try? JSONEncoder()
                    .encode(values)
        else {
            return
        }

        defaults.set(
            data,
            forKey: key
        )
    }

    private func restore() {
        guard
            let data =
                defaults.data(
                    forKey: key
                ),
            let decoded =
                try? JSONDecoder()
                    .decode(
                        [SessionQuickReply]
                            .self,
                        from: data
                    )
        else {
            return
        }

        values = decoded
    }
    func reloadForUser() { values = []; restore() }

}
