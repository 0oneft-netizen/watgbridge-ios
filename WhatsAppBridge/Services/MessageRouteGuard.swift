import Foundation

enum MessageRouteGuard {
    static func accountID(
        for message: Message
    ) -> String {
        let value =
            message.accountID?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            ?? ""

        return value.isEmpty
            ? "default"
            : value
    }

    static func chatJID(
        for message: Message,
        fallback: String
    ) -> String {
        let value =
            message.chatJID
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        return value.isEmpty
            ? fallback
            : value
    }
}
