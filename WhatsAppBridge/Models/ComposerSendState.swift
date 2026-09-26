import Foundation

enum ComposerSendState:
    Equatable {

    case ready
    case sending
    case queued
    case failed(String)

    var busy: Bool {
        switch self {
        case .sending:
            return true
        default:
            return false
        }
    }
}
