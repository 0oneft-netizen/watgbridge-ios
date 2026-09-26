import Foundation

@MainActor
enum ConversationDraftPreview {
    static func text(
        _ conversation:
            Conversation
    ) -> String? {

        let value =
            PersistentDraftStore
                .shared
                .text(
                    conversation:
                        conversation
                )
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard
            !value.isEmpty
        else {
            return nil
        }

        return MessageContentPolicy
            .preview(
                value
            )
    }
}
