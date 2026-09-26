import Foundation

enum InboxSorting {
    static func sorted(
        _ conversations: [Conversation],
        state: ConversationLocalState
    ) -> [Conversation] {
        conversations.sorted { a, b in
            let ap = state.isPinned(a)
            let bp = state.isPinned(b)

            if ap != bp {
                return ap && !bp
            }

            let au = state.isUnread(a)
            let bu = state.isUnread(b)

            if au != bu {
                return au && !bu
            }

            return conversationDate(a) >
                conversationDate(b)
        }
    }

    private static func conversationDate(
        _ conversation: Conversation
    ) -> Int64 {
        Mirror(reflecting: conversation)
            .children
            .first {
                $0.label == "updatedAt" ||
                $0.label == "lastMessageAt" ||
                $0.label == "timestamp"
            }
            .flatMap {
                $0.value as? Int64
            } ?? 0
    }
}
