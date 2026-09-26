import Foundation

enum RetryBackoff {
    static func delay(
        attempt: Int
    ) -> Duration {
        switch attempt {
        case ...0:
            return .zero
        case 1:
            return .seconds(1)
        case 2:
            return .seconds(2)
        case 3:
            return .seconds(5)
        case 4:
            return .seconds(10)
        default:
            return .seconds(20)
        }
    }
}
