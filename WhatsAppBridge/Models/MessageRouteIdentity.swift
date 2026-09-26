import Foundation

struct MessageRouteIdentity: Hashable, Sendable {

    let route:
        ConversationRoute

    let messageID:
        String

    let localID:
        Int64

    init(
        message:
            Message
    ) {
        route =
            ConversationRoute(
                message:
                    message
            )

        messageID =
            message.messageID
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        localID =
            message.id
    }


    var accountID: String {
        route.accountID
    }

    var chatJID: String {
        route.chatJID
    }

    var key: String {
        if !messageID.isEmpty {
            return route.key
                + "|"
                + messageID
        }

        return route.key
            + "|local|"
            + String(localID)
    }
}
