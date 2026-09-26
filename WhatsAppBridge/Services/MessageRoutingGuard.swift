import Foundation

enum MessageRoutingGuard {
    static func belongs(
        _ message: Message,
        to conversation: Conversation
    ) -> Bool {
        let conversationAccount =
            conversation.accountID
            ?? "default"

        let messageAccount =
            message.accountID
            ?? "default"

        return
            conversationAccount ==
                messageAccount
            &&
            conversation.jid ==
                message.chatJID
    }

    static func filter(
        _ messages: [Message],
        for conversation:
            Conversation
    ) -> [Message] {
        messages.filter {
            belongs(
                $0,
                to: conversation
            )
        }
    }
}
