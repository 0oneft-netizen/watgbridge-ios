import SwiftUI

struct AppHealthBadge: View {
    @ObservedObject
    private var network =
        NetworkMonitor.shared

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    var body: some View {
        if needsAttention {
            Image(
                systemName:
                    "exclamationmark.circle.fill"
            )
            .foregroundStyle(
                .orange
            )
            .accessibilityLabel(
                "App needs attention"
            )
        }
    }

    private var needsAttention:
        Bool {

        if !network.isConnected {
            return true
        }

        return sessions.accounts
            .contains {
                $0.status
                    .lowercased()
                    !=
                    "connected"
            }
    }
}
