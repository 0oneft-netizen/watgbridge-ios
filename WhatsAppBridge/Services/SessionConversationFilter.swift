import Foundation

enum SessionConversationFilter {
    static func apply(
        _ conversations:
            [Conversation],
        accountID: String?
    ) -> [Conversation] {
        guard
            let accountID
        else {
            return conversations
        }

        return conversations.filter {
            ($0.accountID
                ?? "default")
            ==
            accountID
        }
    }
}
