import Foundation

enum ChatPerformancePolicy {
    static let maximumRenderedMessages =
        300

    static let initialRenderedMessages =
        120

    static let pageIncrement =
        80

    static func renderWindow(
        _ messages:
            [Message],
        count: Int
    ) -> [Message] {

        let safeCount =
            min(
                max(
                    count,
                    initialRenderedMessages
                ),
                maximumRenderedMessages
            )

        return Array(
            messages.suffix(
                safeCount
            )
        )
    }
}
