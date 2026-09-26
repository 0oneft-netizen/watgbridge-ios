import Foundation
import os

enum ChatHealthDiagnostics {
    private static let log =
        Logger(
            subsystem:
                "com.watgbridge.ios",
            category:
                "ChatHealth"
        )

    static func inspect(
        messages: [Message],
        conversation:
            Conversation
    ) {
        let account =
            conversation.accountID
            ?? "default"

        let wrongRoute =
            messages.filter {
                !MessageRoutingGuard
                    .belongs(
                        $0,
                        to:
                            conversation
                    )
            }

        let duplicateCount =
            messages.count -
            Set(
                messages.map {
                    ($0.accountID
                        ?? "default")
                    + "|"
                    + $0.messageID
                }
            ).count

        if !wrongRoute.isEmpty {
            log.error(
                "Wrong-route messages detected account=\(account, privacy: .private) count=\(wrongRoute.count)"
            )
        }

        if duplicateCount > 0 {
            log.error(
                "Duplicate messages detected count=\(duplicateCount)"
            )
        }

        log.debug(
            "Chat health messages=\(messages.count) account=\(account, privacy: .private)"
        )
    }
}
