import Foundation

enum ConversationTimePresentation {
    static func string(
        timestamp: Int64
    ) -> String {
        let date =
            MessageDatePresentation.date(
                from: timestamp
            )

        let calendar =
            Calendar.current

        if calendar.isDateInToday(date) {
            return date.formatted(
                date: .omitted,
                time: .shortened
            )
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let days =
            calendar.dateComponents(
                [.day],
                from: date,
                to: Date()
            ).day ?? 99

        if days < 7 {
            return date.formatted(
                .dateTime
                    .weekday(.abbreviated)
            )
        }

        return date.formatted(
            .dateTime
                .day()
                .month(.twoDigits)
        )
    }
}
