import Foundation

enum NetworkQuality:
    Equatable {

    case online
    case degraded
    case offline

    var label: String {
        switch self {
        case .online:
            return "Connected"

        case .degraded:
            return "Connection unstable"

        case .offline:
            return "Offline"
        }
    }

    var systemImage: String {
        switch self {
        case .online:
            return "wifi"

        case .degraded:
            return "wifi.exclamationmark"

        case .offline:
            return "wifi.slash"
        }
    }
}
