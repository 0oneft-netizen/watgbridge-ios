import Foundation

enum InboxAccountFilter {
    Hashable {

    case all
    case account(String)

    func matches(
        _ conversation:
            Conversation
    ) -> Bool {

        switch self {
        case .all:
            return true

        case .account(
            let accountID
        ):
            return
                ConversationRoute(
                    conversation:
                        conversation
                )
                .accountID
                ==
                accountID
        }
    }
}
