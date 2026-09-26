import Foundation

struct RealtimeMessageEvent {
    Equatable {

    let accountID: String
    let chatJID: String
    let messageID: String?

    init(
        accountID: String?,
        chatJID: String,
        messageID: String? = nil
    ) {
        let account =
            accountID?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            ?? ""

        self.accountID =
            account.isEmpty
            ? "default"
            : account

        self.chatJID =
            chatJID.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        self.messageID =
            messageID
    }

    var route:
        ConversationRoute {

        ConversationRoute(
            accountID:
                accountID,
            chatJID:
                chatJID
        )
    }
}
