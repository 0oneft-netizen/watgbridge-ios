import Foundation

struct ComposerState:
    Codable,
    Equatable {

    var text: String = ""
    var replyMessageID:
        String?
    var updatedAt:
        Date = Date()
}

@MainActor
final class ComposerStateStore {
    static let shared =
        ComposerStateStore()

    private let defaults =
        UserDefaults.standard

    private let prefix =
        "composer.state."

    private func key(
        accountID: String,
        chatJID: String
    ) -> String {
        prefix
        + accountID
        + "|"
        + chatJID
    }

    func load(
        accountID: String,
        chatJID: String
    ) -> ComposerState {
        guard
            let data =
                defaults.data(
                    forKey:
                        key(
                            accountID:
                                accountID,
                            chatJID:
                                chatJID
                        )
                ),
            let value =
                try? JSONDecoder()
                    .decode(
                        ComposerState.self,
                        from: data
                    )
        else {
            return
                ComposerState()
        }

        return value
    }

    func save(
        _ value:
            ComposerState,
        accountID: String,
        chatJID: String
    ) {
        guard
            let data =
                try? JSONEncoder()
                    .encode(value)
        else {
            return
        }

        defaults.set(
            data,
            forKey:
                key(
                    accountID:
                        accountID,
                    chatJID:
                        chatJID
                )
        )
    }

    func clear(
        accountID: String,
        chatJID: String
    ) {
        defaults.removeObject(
            forKey:
                key(
                    accountID:
                        accountID,
                    chatJID:
                        chatJID
                )
        )
    }
}
