import Foundation

enum ConversationRouteValidator {
    static func isValid(
        _ conversation:
            Conversation
    ) -> Bool {

        ConversationRoute(
            conversation:
                conversation
        )
        .isValid
    }

    static func routeKey(
        _ conversation:
            Conversation
    ) -> String {

        ConversationRoute(
            conversation:
                conversation
        )
        .key
    }
}
