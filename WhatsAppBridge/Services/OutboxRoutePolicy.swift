import Foundation

enum OutboxRoutePolicy {
    static func valid(
        accountID: String?,
        chatJID: String
    ) -> Bool {

        ConversationRoute(
            accountID:
                accountID,
            chatJID:
                chatJID
        )
        .isValid
    }

    static func key(
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
