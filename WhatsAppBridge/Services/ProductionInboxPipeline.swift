import Foundation

@MainActor
enum ProductionInboxPipeline {
    static func visible(
        conversations: [Conversation],
        query: String,
        accountID: String?,
        showArchived: Bool = false
    ) -> [Conversation] {

        let local =
            ConversationLocalState.shared

        let filtered =
            conversations.filter {
                conversation in

                if !showArchived,
                   local.isArchived(
                    conversation
                   ) {
                    return false
                }

                if let accountID {
                    return
                        ConversationRoute(
                            conversation:
                                conversation
                        )
                        .accountID
                        ==
                        accountID
                }

                return true
            }

        let documents =
            ConversationSearchIndex
                .build(
                    filtered
                )

        let searched =
            ConversationSearchIndex
                .search(
                    query:
                        query,
                    documents:
                        documents
                )

        return ProductionInboxSorter
            .sort(
                searched
            )
    }
}
