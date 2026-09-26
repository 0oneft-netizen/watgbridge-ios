import Foundation

enum MessageRetryPolicy {
    static let maximumAttempts =
        5

    static func mayRetry(
        attempts: Int
    ) -> Bool {
        attempts <
            maximumAttempts
    }
}
