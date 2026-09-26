import Foundation

enum ConversationDocumentSearch {
    static func filter(
        _ messages: [Message],
        query: String
    ) -> [Message] {
        let docs =
            messages.filter {
                $0.type
                    .lowercased()
                    ==
                    "document"
                &&
                !MessageMediaPolicy
                    .isViewOnce(
                        $0
                    )
            }

        let q =
            query.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !q.isEmpty else {
            return docs
        }

        return docs.filter {
            ($0.fileName ?? "")
                .range(
                    of: q,
                    options: [
                        .caseInsensitive,
                        .diacriticInsensitive
                    ]
                )
                != nil
            ||
            $0.text.range(
                of: q,
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive
                ]
            )
            != nil
        }
    }
}
