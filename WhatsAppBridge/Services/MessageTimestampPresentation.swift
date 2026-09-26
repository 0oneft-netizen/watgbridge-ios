import Foundation

enum MessageTimestampPresentation {
    static func time(
        _ timestamp:
            Int64
    ) -> String {

        Date(
            timeIntervalSince1970:
                TimeInterval(
                    timestamp
                )
        )
        .formatted(
            date:
                .omitted,
            time:
                .shortened
        )
    }

    static func day(
        _ timestamp:
            Int64
    ) -> String {

        let date =
            Date(
                timeIntervalSince1970:
                    TimeInterval(
                        timestamp
                    )
            )

        if Calendar.current
            .isDateInToday(
                date
            ) {
            return "Today"
        }

        if Calendar.current
            .isDateInYesterday(
                date
            ) {
            return "Yesterday"
        }

        return date.formatted(
            date:
                .abbreviated,
            time:
                .omitted
        )
    }
}
