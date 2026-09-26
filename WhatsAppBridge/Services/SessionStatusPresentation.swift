import Foundation

enum SessionStatusPresentation {
    static func title(
        _ status:
            String
    ) -> String {

        switch status
            .lowercased() {

        case "connected":
            return "Connected"

        case "disconnected":
            return "Disconnected"

        case "reconnect_required":
            return "Reconnect required"

        case "waiting":
            return "Waiting"

        default:
            return "Unknown"
        }
    }

    static func icon(
        _ status:
            String
    ) -> String {

        switch status
            .lowercased() {

        case "connected":
            return "checkmark.circle.fill"

        case "disconnected":
            return "wifi.slash"

        case "reconnect_required":
            return "exclamationmark.triangle.fill"

        default:
            return "clock"
        }
    }
}
