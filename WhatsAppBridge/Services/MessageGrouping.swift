import Foundation

enum MessageGrouping {
    static func belongsTogether(
        _ first: Message,
        _ second: Message
    ) -> Bool {
        guard
            first.fromMe == second.fromMe,
            first.senderJID == second.senderJID
        else {
            return false
        }

        let firstDate =
            MessageDatePresentation.date(
                from: first.createdAt
            )

        let secondDate =
            MessageDatePresentation.date(
                from: second.createdAt
            )

        guard Calendar.current.isDate(
            firstDate,
            inSameDayAs: secondDate
        ) else {
            return false
        }

        return abs(
            secondDate.timeIntervalSince(
                firstDate
            )
        ) < 120
    }

    static func isGroupStart(
        message: Message,
        previous: Message?
    ) -> Bool {
        guard let previous else {
            return true
        }

        return !belongsTogether(
            previous,
            message
        )
    }

    static func isGroupEnd(
        message: Message,
        next: Message?
    ) -> Bool {
        guard let next else {
            return true
        }

        return !belongsTogether(
            message,
            next
        )
    }
}
