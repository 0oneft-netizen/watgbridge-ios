import Foundation

enum MessageGrouping {
    static func beginsGroup(
        _ message: Message,
        previous: Message?
    ) -> Bool {
        guard let previous else {
            return true
        }

        if previous.fromMe != message.fromMe {
            return true
        }

        if previous.senderJID != message.senderJID {
            return true
        }

        return abs(
            message.createdAt -
            previous.createdAt
        ) > 300
    }

    static func endsGroup(
        _ message: Message,
        next: Message?
    ) -> Bool {
        guard let next else {
            return true
        }

        if next.fromMe != message.fromMe {
            return true
        }

        if next.senderJID != message.senderJID {
            return true
        }

        return abs(
            next.createdAt -
            message.createdAt
        ) > 300
    }

    static func needsDateSeparator(
        _ message: Message,
        previous: Message?
    ) -> Bool {
        guard let previous else {
            return true
        }

        let calendar = Calendar.current

        let a = Date(
            timeIntervalSince1970:
                TimeInterval(message.createdAt)
        )

        let b = Date(
            timeIntervalSince1970:
                TimeInterval(previous.createdAt)
        )

        return !calendar.isDate(
            a,
            inSameDayAs: b
        )
    }
}
