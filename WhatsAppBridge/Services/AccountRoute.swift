import Foundation

struct AccountRoute:
    Hashable,
    Sendable
{
    let accountID: String
    let chatJID: String

    init(
        accountID: String?,
        chatJID: String
    ) {
        self.accountID =
            accountID ?? "default"

        self.chatJID =
            chatJID
    }

    init(
        conversation: Conversation
    ) {
        self.init(
            accountID:
                conversation.accountID,
            chatJID:
                conversation.jid
        )
    }

    init(
        message: Message
    ) {
        self.init(
            accountID:
                message.accountID,
            chatJID:
                message.chatJID
        )
    }
}
