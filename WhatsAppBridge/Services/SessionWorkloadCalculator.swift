import Foundation

@MainActor
enum SessionWorkloadCalculator {
    static func calculate(
        conversations:
            [Conversation]
    ) -> [SessionWorkload] {

        let state =
            ConversationLocalState.shared

        let workflow =
            CustomerWorkflowStore.shared

        let followups =
            CustomerFollowUpStore.shared

        let groups =
            Dictionary(
                grouping:
                    conversations
            ) {
                $0.accountID
                    ?? "default"
            }

        return groups.map {
            accountID,
            items in

            SessionWorkload(
                accountID:
                    accountID,

                conversations:
                    items.count,

                unread:
                    items.filter {
                        state.isUnread($0)
                    }.count,

                priority:
                    items.filter {
                        workflow
                            .value(
                                for: $0
                            )
                            .priority
                    }.count,

                followUps:
                    items.filter {
                        guard
                            let follow =
                                followups
                                    .value(
                                        for: $0
                                    )
                        else {
                            return false
                        }

                        return
                            !follow.completed
                    }.count
            )
        }
        .sorted {
            $0.unread >
                $1.unread
        }
    }
}
