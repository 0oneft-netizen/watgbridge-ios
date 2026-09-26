import Foundation

@MainActor
final class MediaTransferRegistry:
    ObservableObject {

    static let shared =
        MediaTransferRegistry()

    @Published
    private(set)
    var states:
        [String: MediaTransferState] =
            [:]

    func key(
        accountID: String,
        messageID: String
    ) -> String {
        accountID
        + "|"
        + messageID
    }

    func state(
        accountID: String,
        messageID: String
    ) -> MediaTransferState {
        states[
            key(
                accountID:
                    accountID,
                messageID:
                    messageID
            )
        ]
        ?? .idle
    }

    func set(
        _ state:
            MediaTransferState,
        accountID: String,
        messageID: String
    ) {
        states[
            key(
                accountID:
                    accountID,
                messageID:
                    messageID
            )
        ] = state
    }

    func clear(
        accountID: String,
        messageID: String
    ) {
        states.removeValue(
            forKey:
                key(
                    accountID:
                        accountID,
                    messageID:
                        messageID
                )
        )
    }
}
