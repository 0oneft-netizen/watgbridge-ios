import Foundation

enum OutgoingIntentFactory {
    static func text(
        conversation:
            Conversation,
        text: String
    ) -> OutgoingSendIntent {

        OutgoingSendIntent(
            route:
                ConversationRoute(
                    conversation:
                        conversation
                ),
            kind:
                .text,
            fingerprint:
                OutgoingTextPolicy
                    .normalized(
                        text
                    )
        )
    }

    static func messageAction(
        message:
            Message,
        kind:
            OutgoingSendIntent.Kind
    ) -> OutgoingSendIntent {

        OutgoingSendIntent(
            route:
                ConversationRoute(
                    message:
                        message
                ),
            kind:
                kind,
            fingerprint:
                MessageIdentity
                    .key(
                        message
                    )
        )
    }
}
