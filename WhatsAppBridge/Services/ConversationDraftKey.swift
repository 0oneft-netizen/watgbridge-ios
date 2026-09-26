import Foundation

enum ConversationDraftKey {
    static func value(
        _ conversation:
            Conversation
    ) -> String {

        ConversationRoute(
            conversation:
                conversation
        )
        .key
    }

    static func value(
        accountID: String?,
        chatJID: String
    ) -> String {

        ConversationRoute(
            accountID:
                accountID,
            chatJID:
                chatJID
        )
        .key
    }
}
