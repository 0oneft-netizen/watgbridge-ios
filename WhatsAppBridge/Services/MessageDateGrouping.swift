import Foundation

enum MessageDateGrouping {
    static func title(
        timestamp: Int64
    ) -> String {
        let date =
            Date(
                timeIntervalSince1970:
                    TimeInterval(
                        timestamp
                    )
            )

        let calendar =
            Calendar.current

        if calendar.isDateInToday(
            date
        ) {
            return "Today"
        }

        if calendar.isDateInYesterday(
            date
        ) {
            return "Yesterday"
        }

        return date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }

    static func needsDivider(
        previous: Message?,
        current: Message
    ) -> Bool {
        guard
            let previous
        else {
            return true
        }

        let a =
            Date(
                timeIntervalSince1970:
                    TimeInterval(
                        previous.createdAt
                    )
            )

        let b =
            Date(
                timeIntervalSince1970:
                    TimeInterval(
                        current.createdAt
                    )
            )

        return !Calendar
            .current
            .isDate(
                a,
                inSameDayAs: b
            )
    }
}
