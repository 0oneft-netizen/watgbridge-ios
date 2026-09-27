import Foundation

struct UnifiedConversationRoute:
    Hashable,
    Identifiable {

    let accountID: String
    let chatJID: String

    var id: String {
        "\(accountID)|\(chatJID)"
    }

    static func route(
        for message: Message
    ) -> UnifiedConversationRoute {
        UnifiedConversationRoute(
            accountID:
                message.accountID
                ?? "default",
            chatJID:
                message.chatJID
        )
    }

    static func route(
        for conversation:
            Conversation
    ) -> UnifiedConversationRoute {
        UnifiedConversationRoute(
            accountID:
                conversation.accountID
                ?? "default",
            chatJID:
                conversation.jid
        )
    }
}
