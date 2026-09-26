import Foundation

@MainActor
enum ProductionInboxSorter {
    static func sort(
        _ conversations:
            [Conversation]
    ) -> [Conversation] {

        let local =
            ConversationLocalState.shared

        let workflow =
            CustomerWorkflowStore.shared

        return conversations.sorted {
            left,
            right in

            let lp =
                workflow
                    .value(
                        for: left
                    )
                    .priority

            let rp =
                workflow
                    .value(
                        for: right
                    )
                    .priority

            if lp != rp {
                return lp
            }

            let lu =
                local
                    .isUnread(left)

            let ru =
                local
                    .isUnread(right)

            if lu != ru {
                return lu
            }

            return
                (left.updatedAt ?? 0)
                >
                (right.updatedAt ?? 0)
        }
    }
}
