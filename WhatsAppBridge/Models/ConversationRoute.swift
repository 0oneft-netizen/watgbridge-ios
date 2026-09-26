import Foundation

struct ConversationRoute {
    Hashable,
    Codable {

    let accountID: String
    let chatJID: String

    init(
        accountID: String?,
        chatJID: String
    ) {
        self.accountID =
            Self.normalizeAccount(
                accountID
            )

        self.chatJID =
            chatJID.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }

    init(
        conversation:
            Conversation
    ) {
        self.init(
            accountID:
                conversation.accountID,
            chatJID:
                conversation.jid
        )
    }

    init(
        message:
            Message
    ) {
        self.init(
            accountID:
                message.accountID,
            chatJID:
                message.chatJID
        )
    }

    var key: String {
        accountID
        + "|"
        + chatJID
    }

    var isValid: Bool {
        !accountID.isEmpty
        &&
        !chatJID.isEmpty
    }

    private static func normalizeAccount(
        _ value: String?
    ) -> String {

        let cleaned =
            value?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            ?? ""

        return cleaned.isEmpty
            ? "default"
            : cleaned
    }
}
