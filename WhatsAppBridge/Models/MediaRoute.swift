import Foundation

struct MediaRoute:
    Hashable {

    let conversation:
        ConversationRoute

    let messageID:
        String?

    init(
        conversation:
            Conversation
    ) {
        self.conversation =
            ConversationRoute(
                conversation:
                    conversation
            )

        self.messageID = nil
    }

    init(
        message:
            Message
    ) {
        self.conversation =
            ConversationRoute(
                message:
                    message
            )

        self.messageID =
            message.messageID
    }
}
