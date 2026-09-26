import Foundation

struct CustomerFollowUp {
    Codable,
    Equatable {

    var dueAt: Date
    var note: String
    var completed: Bool
}

@MainActor
final class CustomerFollowUpStore:
    ObservableObject {

    static let shared =
        CustomerFollowUpStore()

    @Published
    private(set)
    var values:
        [String: CustomerFollowUp] =
            [:]

    private let defaults =
        UserDefaults.standard

    private let storageKey =
        "customer.followups.v1"

    private init() {
        restore()
    }

    func key(
        _ conversation:
            Conversation
    ) -> String {
        (conversation.accountID
            ?? "default")
        + "|"
        + conversation.jid
    }

    func value(
        for conversation:
            Conversation
    ) -> CustomerFollowUp? {
        values[
            key(conversation)
        ]
    }

    func set(
        conversation:
            Conversation,
        dueAt: Date,
        note: String
    ) {
        values[
            key(conversation)
        ] =
            CustomerFollowUp(
                dueAt: dueAt,
                note:
                    note.trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    ),
                completed: false
            )

        persist()
    }

    func complete(
        _ conversation:
            Conversation
    ) {
        let k =
            key(conversation)

        guard
            var item =
                values[k]
        else {
            return
        }

        item.completed = true
        values[k] = item
        persist()
    }

    func remove(
        _ conversation:
            Conversation
    ) {
        values.removeValue(
            forKey:
                key(conversation)
        )

        persist()
    }

    func isDue(
        _ conversation:
            Conversation
    ) -> Bool {
        guard
            let item =
                value(
                    for:
                        conversation
                ),
            !item.completed
        else {
            return false
        }

        return item.dueAt <= Date()
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
            forKey:
                storageKey
        )
    }

    private func restore() {
        guard
            let data =
                defaults.data(
                    forKey:
                        storageKey
                ),
            let decoded =
                try? JSONDecoder()
                    .decode(
                        [String:
                            CustomerFollowUp]
                            .self,
                        from: data
                    )
        else {
            return
        }

        values = decoded
    }
}
