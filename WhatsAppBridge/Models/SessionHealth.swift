import Foundation

enum SessionHealthLevel {
    String,
    Codable {

    case healthy
    case attention
    case offline
    case unknown

    var title: String {
        switch self {
        case .healthy:
            return "Connected"
        case .attention:
            return "Needs attention"
        case .offline:
            return "Disconnected"
        case .unknown:
            return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .healthy:
            return "checkmark.circle.fill"
        case .attention:
            return "exclamationmark.triangle.fill"
        case .offline:
            return "wifi.slash"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

struct SessionHealth {
    Identifiable,
    Equatable {

    let accountID: String
    let displayName: String
    let status: String
    let accountType: String?

    var id: String {
        accountID
    }

    var level: SessionHealthLevel {
        switch status.lowercased() {
        case "connected":
            return .healthy

        case "reconnect_required":
            return .attention

        case "disconnected":
            return .offline

        default:
            return .unknown
        }
    }
}
