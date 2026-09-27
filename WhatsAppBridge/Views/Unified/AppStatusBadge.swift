import SwiftUI

struct AppStatusBadge: View {
    let status: String

    private var normalized: String {
        status
            .lowercased()
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    private var icon: String {
        switch normalized {
        case "connected":
            return "checkmark.circle.fill"

        case "disconnected":
            return "wifi.slash"

        case "reconnect_required":
            return "exclamationmark.triangle.fill"

        default:
            return "clock.fill"
        }
    }

    private var label: String {
        switch normalized {
        case "connected":
            return "Connected"

        case "disconnected":
            return "Disconnected"

        case "reconnect_required":
            return "Reconnect Required"

        default:
            return status.isEmpty
                ? "Unknown"
                : status
        }
    }

    var body: some View {
        Label(
            label,
            systemImage: icon
        )
        .font(
            .caption.weight(
                .semibold
            )
        )
        .foregroundStyle(
            normalized == "connected"
            ? AppVisualDesign.accent
            : Color.secondary
        )
    }
}
