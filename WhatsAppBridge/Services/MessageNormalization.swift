import Foundation

enum MessageNormalization {
    static func normalize(
        _ messages: [Message],
        conversation: Conversation
    ) -> [Message] {
        let routed =
            MessageRoutingGuard.filter(
                messages,
                for: conversation
            )

        let normalized =
            MessageMerge
                .normalized(
                    routed
                )

        return ChatMemoryPolicy
            .trim(normalized)
    }
}
