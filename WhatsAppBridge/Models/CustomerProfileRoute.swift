import Foundation

struct CustomerProfileRoute:
    Hashable {

    let conversation:
        ConversationRoute

    init(
        conversation:
            Conversation
    ) {
        self.conversation =
            ConversationRoute(
                conversation:
                    conversation
            )
    }
}
