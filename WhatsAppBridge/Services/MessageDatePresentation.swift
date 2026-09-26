import Foundation

enum MessageDatePresentation {
    static func date(
        from timestamp: Int64
    ) -> Date {
        let seconds: TimeInterval

        if timestamp > 10_000_000_000 {
            seconds =
                TimeInterval(timestamp) / 1000
        } else {
            seconds =
                TimeInterval(timestamp)
        }

        return Date(
            timeIntervalSince1970: seconds
        )
    }

    static func time(
        _ timestamp: Int64
    ) -> String {
        date(from: timestamp).formatted(
            date: .omitted,
            time: .shortened
        )
    }

    static func dayLabel(
        _ timestamp: Int64,
        now: Date = Date()
    ) -> String {
        let value = date(from: timestamp)
        let calendar = Calendar.current

        if calendar.isDateInToday(value) {
            return "Today"
        }

        if calendar.isDateInYesterday(value) {
            return "Yesterday"
        }

        let days = calendar.dateComponents(
            [.day],
            from: value,
            to: now
        ).day ?? 999

        if days < 7 {
            return value.formatted(
                .dateTime.weekday(.wide)
            )
        }

        return value.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }

    static func startsNewDay(
        current: Message,
        previous: Message?
    ) -> Bool {
        guard let previous else {
            return true
        }

        return !Calendar.current.isDate(
            date(from: current.createdAt),
            inSameDayAs:
                date(from: previous.createdAt)
        )
    }
}
