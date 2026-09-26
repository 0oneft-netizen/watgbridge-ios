import Foundation

struct InboxCountSnapshot {
    Equatable {

    let total: Int
    let unread: Int
    let priority: Int
    let followUp: Int
    let archived: Int
}

@MainActor
enum InboxCounters {
    static func calculate(
        _ conversations:
            [Conversation]
    ) -> InboxCountSnapshot {

        let state =
            ConversationLocalState
                .shared

        let workflow =
            CustomerWorkflowStore
                .shared

        let followups =
            CustomerFollowUpStore
                .shared

        return InboxCountSnapshot(
            total:
                conversations
                    .filter {
                        !state
                            .isArchived(
                                $0
                            )
                    }
                    .count,

            unread:
                conversations
                    .filter {
                        state
                            .isUnread(
                                $0
                            )
                        &&
                        !state
                            .isArchived(
                                $0
                            )
                    }
                    .count,

            priority:
                conversations
                    .filter {
                        workflow
                            .value(
                                for: $0
                            )
                            .priority
                        &&
                        !state
                            .isArchived(
                                $0
                            )
                    }
                    .count,

            followUp:
                conversations
                    .filter {
                        guard
                            let item =
                                followups
                                    .value(
                                        for:
                                            $0
                                    )
                        else {
                            return false
                        }

                        return
                            !item.completed
                    }
                    .count,

            archived:
                conversations
                    .filter {
                        state
                            .isArchived(
                                $0
                            )
                    }
                    .count
        )
    }
}
