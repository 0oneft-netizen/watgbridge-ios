import Foundation

enum MessageRouteValidator {
    static func isValid(
        _ message:
            Message
    ) -> Bool {

        let route =
            ConversationRoute(
                message:
                    message
            )

        return route.isValid
            &&
            !message.messageID
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
    }

    static func key(
        _ message:
            Message
    ) -> String {

        MessageRouteIdentity(
            message:
                message
        )
        .key
    }
}
