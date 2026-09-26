import Foundation

@MainActor
enum SessionQuickReplyMatcher {
    static func matches(
        accountID: String,
        composerText: String
    ) -> [SessionQuickReply] {

        guard
            composerText
                .hasPrefix("/")
        else {
            return []
        }

        let query =
            String(
                composerText
                    .dropFirst()
            )
            .lowercased()

        return SessionQuickReplyStore
            .shared
            .replies(
                accountID:
                    accountID
            )
            .filter {
                query.isEmpty
                ||
                $0.shortcut
                    .lowercased()
                    .contains(
                        query
                    )
            }
    }
}
