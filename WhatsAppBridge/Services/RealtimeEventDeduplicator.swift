import Foundation

actor RealtimeEventDeduplicator {
    static let shared =
        RealtimeEventDeduplicator()

    private var recent:
        [String: Date] = [:]

    private let lifetime:
        TimeInterval = 10

    func shouldProcess(
        accountID: String,
        chatJID: String,
        messageID: String
    ) -> Bool {
        cleanup()

        let key =
            UserWorkspace.id + "|" + accountID
            + "|"
            + chatJID
            + "|"
            + messageID

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
