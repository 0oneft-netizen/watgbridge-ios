import Foundation

enum RealtimeRouteMatcher {
    static func matches(
        event:
            RealtimeMessageEvent,
        conversation:
            Conversation
    ) -> Bool {

        event.route
        ==
        ConversationRoute(
            conversation:
                conversation
        )
    }

    static func matches(
        eventAccountID:
            String?,
        eventChatJID:
            String?,
        conversation:
            Conversation
    ) -> Bool {

        guard
            let eventChatJID,
            !eventChatJID
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
        else {
            return false
        }

        return matches(
            event:
                RealtimeMessageEvent(
                    accountID:
                        eventAccountID,
                    chatJID:
                        eventChatJID
                ),
            conversation:
                conversation
        )
    }
}
