import Foundation

enum OutboxBackoffPolicy {
    static let maximumAttempts =
        5

    static func delay(
        attempt: Int
    ) -> TimeInterval {

        switch attempt {
        case ...0:
            return 0

        case 1:
            return 2

        case 2:
            return 5

        case 3:
            return 15

        case 4:
            return 30

        default:
            return 60
        }
    }

    static func mayRetry(
        attempt: Int
    ) -> Bool {

        attempt <
            maximumAttempts
    }
}
