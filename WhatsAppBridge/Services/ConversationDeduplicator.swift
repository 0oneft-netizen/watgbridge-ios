import Foundation

enum ConversationDeduplicator {
    static func normalize(
        _ values:
            [Conversation]
    ) -> [Conversation] {
        var seen =
            Set<String>()

        var result:
            [Conversation] = []

        for conversation in values {
            let key =
                (conversation
                    .accountID
                    ?? "default")
                + "|"
                + conversation.jid

            guard
                seen.insert(
                    key
                )
                .inserted
            else {
                continue
            }

            result.append(
                conversation
            )
        }

        return result
    }
}
