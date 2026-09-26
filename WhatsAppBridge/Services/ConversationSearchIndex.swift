import Foundation

enum ConversationSearchIndex {
    static func build(
        _ conversations:
            [Conversation]
    ) -> [ConversationSearchDocument] {

        conversations.map {
            conversation in

            let title =
                CustomerIdentityPresentation
                    .title(
                        conversation:
                            conversation
                    )

            let phone =
                ChatIdentity
                    .customerPhone(
                        from:
                            conversation.jid
                    )

            let last =
                conversation
                    .lastMessage
                ?? ""

            return
                ConversationSearchDocument(
                    conversation:
                        conversation,
                    normalizedText:
                        SearchNormalization
                            .value(
                                [
                                    title,
                                    phone,
                                    last
                                ]
                                .joined(
                                    separator:
                                        " "
                                )
                            )
                )
        }
    }

    static func search(
        query: String,
        documents:
            [ConversationSearchDocument]
    ) -> [Conversation] {

        let q =
            SearchNormalization
                .value(
                    query
                )

        guard
            !q.isEmpty
        else {
            return documents.map {
                $0.conversation
            }
        }

        return documents
            .filter {
                $0.normalizedText
                    .contains(q)
            }
            .map {
                $0.conversation
            }
    }
}
