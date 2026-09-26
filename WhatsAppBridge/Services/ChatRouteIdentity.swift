import Foundation

struct ChatRouteIdentity {
    let accountID: String
    let chatJID: String

    init(
        conversation: Conversation
    ) {
        accountID =
            conversation.accountID
            ?? "default"

        chatJID =
            conversation.jid
    }

    var storageKey: String {
        accountID + "|" + chatJID
    }
}
