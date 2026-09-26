import Foundation

@MainActor
enum InboxSearchEngine {
    static func filter(
        _ conversations:
            [Conversation],
        query: String
    ) -> [Conversation] {
        let q =
            query.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !q.isEmpty else {
            return conversations
        }

        return conversations.filter {
            conversation in

            let name =
                ChatIdentity
                    .customerName(
                        conversation:
                            conversation
                    )

            let phone =
                ChatIdentity
                    .customerPhone(
                        from:
                            conversation.jid
                    )

            let metadata =
                CustomerMetadataStore
                    .shared
                    .metadata(
                        for:
                            conversation
                    )

            let values =
                [
                    name,
                    phone,
                    metadata.note
                ]
                +
                metadata.labels

            return values.contains {
                $0.range(
                    of: q,
                    options: [
                        .caseInsensitive,
                        .diacriticInsensitive
                    ]
                ) != nil
            }
        }
    }
}
