import Foundation

enum MessageLoadState: Equatable {
    case idle
    case loadingInitial
    case loadingOlder
    case refreshing
    case loaded
    case failed(String)

    var isBusy: Bool {
        switch self {
        case .loadingInitial,
             .loadingOlder,
             .refreshing:
            return true

        default:
            return false
        }
    }
}
