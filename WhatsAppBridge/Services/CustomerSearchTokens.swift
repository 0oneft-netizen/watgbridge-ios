import Foundation

@MainActor
enum CustomerSearchTokens {
    static func values(
        for conversation:
            Conversation
    ) -> [String] {
        let metadata =
            CustomerMetadataStore
                .shared
                .metadata(
                    for:
                        conversation
                )

        let workflow =
            CustomerWorkflowStore
                .shared
                .value(
                    for:
                        conversation
                )

        return [
            ChatIdentity
                .customerName(
                    conversation:
                        conversation
                ),
            CustomerPhoneFormatter
                .display(
                    from:
                        conversation.jid
                ),
            metadata.note,
            workflow.stage.title
        ]
        +
        metadata.labels
    }
}
