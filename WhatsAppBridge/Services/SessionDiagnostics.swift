import Foundation

@MainActor
enum SessionDiagnostics {
    static func snapshots(
        accounts:
            [SessionAccountDTO],
        conversations:
            [Conversation]
    ) -> [SessionDiagnosticSnapshot] {

        accounts.map {
            account in

            let chats =
                conversations.filter {
                    ($0.accountID
                        ?? "default")
                    ==
                    account.id
                }

            let unread =
                chats.filter {
                    ConversationLocalState
                        .shared
                        .isUnread($0)
                }
                .count

            return
                SessionDiagnosticSnapshot(
                    accountID:
                        account.id,
                    displayName:
                        account
                            .displayName,
                    status:
                        account.status,
                    accountType:
                        account
                            .accountType,
                    conversationCount:
                        chats.count,
                    unreadCount:
                        unread
                )
        }
    }
}
