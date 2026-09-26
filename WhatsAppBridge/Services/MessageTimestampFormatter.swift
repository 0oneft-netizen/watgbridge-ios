import Foundation

enum MessageTimestampFormatter {
    private static let formatter:
        DateFormatter = {
        let value =
            DateFormatter()

        value.dateStyle =
            .none

        value.timeStyle =
            .short

        return value
    }()

    static func string(
        _ timestamp: Int64
    ) -> String {
        formatter.string(
            from:
                MessageTimestamp.date(timestamp)
        )
    }
}
