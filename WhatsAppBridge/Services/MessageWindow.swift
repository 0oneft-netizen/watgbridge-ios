import Foundation

enum MessageWindow {
    static let initialCount =
        120

    static let expansionCount =
        100

    static func initial(
        _ messages:
            [Message]
    ) -> [Message] {
        Array(
            messages.suffix(
                initialCount
            )
        )
    }

    static func expanded(
        messages:
            [Message],
        currentCount:
            Int
    ) -> [Message] {

        let count =
            min(
                messages.count,
                currentCount
                +
                expansionCount
            )

        return Array(
            messages.suffix(
                count
            )
        )
    }
}
