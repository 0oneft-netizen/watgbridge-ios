import Foundation

enum MediaTransferState {
    Equatable {

    case idle
    case preparing
    case transferring(Double?)
    case complete
    case failed(String)

    var isBusy: Bool {
        switch self {
        case .preparing,
             .transferring:
            return true

        default:
            return false
        }
    }
}
