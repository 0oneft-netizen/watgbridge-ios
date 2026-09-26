import Foundation

actor OutgoingMessageDeduplicator {
    static let shared =
        OutgoingMessageDeduplicator()

    private var recent:
        [String: Date] = [:]

    private let lifetime:
        TimeInterval = 2

    func maySend(
        accountID: String,
        chatJID: String,
        text: String
    ) -> Bool {

        cleanup()

        let normalized =
            text.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        let key =
            accountID
            + "|"
            + chatJID
            + "|"
            + normalized

        if recent[key] != nil {
            return false
        }

        recent[key] =
            Date()

        return true
    }

    private func cleanup() {
        let cutoff =
            Date()
                .addingTimeInterval(
                    -lifetime
                )

        recent =
            recent.filter {
                $0.value >
                    cutoff
            }
    }
}
