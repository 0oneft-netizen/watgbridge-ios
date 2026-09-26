import Foundation

enum OutgoingMessageState {
    case sending
    case sent
    case failed

    var symbol: String {
        switch self {
        case .sending:
            return "clock"

        case .sent:
            return "checkmark"

        case .failed:
            return "exclamationmark.circle.fill"
        }
    }
}
