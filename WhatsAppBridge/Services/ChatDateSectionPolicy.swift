import Foundation

enum ChatDateSectionPolicy {
    static func needsSeparator(
        previous:
            Message?,
        current:
            Message
    ) -> Bool {

        guard
            let previous
        else {
            return true
        }

        let calendar =
            Calendar.current

        let previousDate =
            Date(
                timeIntervalSince1970:
                    TimeInterval(
                        previous.createdAt
                    )
            )

        let currentDate =
            Date(
                timeIntervalSince1970:
                    TimeInterval(
                        current.createdAt
                    )
            )

        return !calendar.isDate(
            previousDate,
            inSameDayAs:
                currentDate
        )
    }
}
