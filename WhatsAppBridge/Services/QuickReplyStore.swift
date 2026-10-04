import Foundation

struct QuickReply:
    Identifiable,
    Codable,
    Equatable {

    let id: UUID
    var shortcut: String
    var text: String
}

@MainActor
final class QuickReplyStore:
    ObservableObject {

    static let shared =
        QuickReplyStore()

    @Published
    private(set)
    var replies: [QuickReply] = []

    private var defaults: UserDefaults { UserWorkspace.defaults }

    private let key =
        "business.quick.replies.v1"

    private init() {
        restore()
    }

    func add(
        shortcut: String,
        text: String
    ) {
        let s =
            shortcut.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        let t =
            text.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard
            !s.isEmpty,
            !t.isEmpty
        else {
            return
        }

        replies.append(
            QuickReply(
                id: UUID(),
                shortcut: s,
                text: t
            )
        )

        persist()
    }

    func delete(
        id: UUID
    ) {
        replies.removeAll {
            $0.id == id
        }

        persist()
    }

    func matching(
        _ query: String
    ) -> [QuickReply] {
        let q =
            query.lowercased()

        guard !q.isEmpty else {
            return replies
        }

        return replies.filter {
            $0.shortcut
                .lowercased()
                .contains(q)
            ||
            $0.text
                .lowercased()
                .contains(q)
        }
    }

    private func persist() {
        guard
            let data =
                try? JSONEncoder()
                    .encode(replies)
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
                        [QuickReply].self,
                        from: data
                    )
        else {
            return
        }

        replies = decoded
    }
    func reloadForUser() { replies = []; restore() }

}
