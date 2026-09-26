import Foundation

enum RoutingAssertions {
    static func validate(
        conversation:
            Conversation
    ) {
        #if DEBUG
        assert(
            ConversationRoute(
                conversation:
                    conversation
            )
            .isValid,
            "Invalid conversation route"
        )
        #endif
    }

    static func validate(
        message:
            Message
    ) {
        #if DEBUG
        assert(
            ConversationRoute(
                message:
                    message
            )
            .isValid,
            "Invalid message route"
        )
        #endif
    }
}
