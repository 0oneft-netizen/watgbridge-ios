import Foundation

enum MessageTimestamp {
    static func date(_ value: Int64) -> Date {
        let seconds: TimeInterval

        if value > 10_000_000_000 {
            seconds = TimeInterval(value) / 1000
        } else {
            seconds = TimeInterval(value)
        }

        return Date(timeIntervalSince1970: seconds)
    }

    static func shortTime(_ value: Int64) -> String {
        date(value).formatted(
            date: .omitted,
            time: .shortened
        )
    }

    static func shortDateTime(_ value: Int64) -> String {
        date(value).formatted(
            date: .abbreviated,
            time: .shortened
        )
    }
}
