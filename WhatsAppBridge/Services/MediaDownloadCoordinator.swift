import Foundation

actor MediaDownloadCoordinator {
    static let shared =
        MediaDownloadCoordinator()

    private var running =
        Set<String>()

    func begin(
        _ message: Message
    ) -> Bool {
        let key =
            (message.accountID
                ?? "default")
            + "|"
            + message.messageID

        guard
            !running.contains(
                key
            )
        else {
            return false
        }

        running.insert(
            key
        )

        return true
    }

    func finish(
        _ message: Message
    ) {
        let key =
            (message.accountID
                ?? "default")
            + "|"
            + message.messageID

        running.remove(
            key
        )
    }
}
