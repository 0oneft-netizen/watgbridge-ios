import Foundation

enum MultiAccountRouteInvariant {
    static func accountID(
        for message: Message,
        fallback: String?
    ) -> String {
        let direct = message.accountID?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let direct, !direct.isEmpty {
            return direct
        }

        let fallback = fallback?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let fallback, !fallback.isEmpty {
            return fallback
        }

        return "default"
    }

    static func matches(
        message: Message,
        accountID: String?,
        chatJID: String
    ) -> Bool {
        let expectedAccount = (
            accountID ?? "default"
        )

        let actualAccount = (
            message.accountID ?? "default"
        )

        return actualAccount == expectedAccount
            && message.chatJID == chatJID
    }

    static func conversationKey(
        accountID: String?,
        chatJID: String
    ) -> String {
        "\(accountID ?? "default")|\(chatJID)"
    }
}
