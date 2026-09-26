import Foundation

struct MessageRouteIdentity:
    Hashable,
    Sendable
{
    let accountID: String
    let chatJID: String
    let messageID: String

    init(
        message: Message
    ) {
        accountID =
            message.accountID
            ?? "default"

        chatJID =
            message.chatJID

        messageID =
            message.messageID
    }
}
