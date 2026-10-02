import Foundation
import os

enum ChatPerformanceMonitor {
    private static let logger =
        Logger(
            subsystem:
                "com.watgbridge.ios",
            category: "Chat"
        )

    static func synced(changed: Int, reset: Bool, duration: Duration) {
        logger.debug("Message sync changed=\(changed) reset=\(reset) duration=\(String(describing: duration), privacy: .public)")
    }

    static func loaded(
        count: Int,
        accountID: String,
        chatJID: String
    ) {
        logger.debug(
            "Loaded \(count) messages account=\(accountID, privacy: .private) chat=\(chatJID, privacy: .private)"
        )
    }

    static func sendFailed(
        accountID: String,
        chatJID: String,
        error: Error
    ) {
        logger.error(
            "Send failed account=\(accountID, privacy: .private) chat=\(chatJID, privacy: .private) error=\(error.localizedDescription, privacy: .public)"
        )
    }
}
