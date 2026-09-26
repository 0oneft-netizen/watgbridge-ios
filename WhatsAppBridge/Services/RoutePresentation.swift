import Foundation

enum RoutePresentation {
    static func safeDescription(
        accountID: String?,
        chatJID: String
    ) -> String {
        let account =
            accountID ?? "default"

        return "\(account)|\(chatJID)"
    }

    static func matches(
        accountID: String?,
        chatJID: String,
        conversation: Conversation
    ) -> Bool {
        (conversation.accountID
            ?? "default")
            == (accountID ?? "default")
        && conversation.jid
            == chatJID
    }
}
