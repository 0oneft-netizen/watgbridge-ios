import Foundation

@MainActor
enum InboxFilterEngine {
    static func apply(
        conversations:
            [Conversation],
        account:
            InboxAccountFilter,
        query: String
    ) -> [Conversation] {

        var values =
            conversations.filter {
                account.matches($0)
            }

        let q =
            SearchNormalization
                .value(
                    query
                )

        if !q.isEmpty {
            let documents =
                ConversationSearchIndex
                    .build(
                        values
                    )

            values =
                ConversationSearchIndex
                    .search(
                        query:
                            q,
                        documents:
                            documents
                    )
        }

        return ProductionInboxSorter
            .sort(
                values
            )
    }
}
