import Foundation

struct SessionConversationCount:
    Identifiable,
    Equatable {

    let accountID: String
    let count: Int

    var id: String {
        accountID
    }
}

enum SessionConversationCounters {
    static func calculate(
        _ conversations:
            [Conversation]
    ) -> [SessionConversationCount] {

        let groups =
            Dictionary(
                grouping:
                    conversations
            ) {
                $0.accountID
                    ?? "default"
            }

        return groups
            .map {
                SessionConversationCount(
                    accountID:
                        $0.key,
                    count:
                        $0.value.count
                )
            }
            .sorted {
                $0.count >
                    $1.count
            }
    }
}
