import Foundation

struct MessageRouteIdentity:
    Hashable {

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
