import Foundation

@MainActor
enum QuickReplyMatcher {
    static func matches(
        composerText:
            String
    ) -> [QuickReply] {
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

        return QuickReplyStore
            .shared
            .matching(query)
    }
}
