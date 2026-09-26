import SwiftUI

struct SessionStatusView: View {
    let session: SessionIdentity

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    session.isConnected
                    ? ChatDesign.accent
                    : Color.secondary
                )
                .frame(
                    width: 7,
                    height: 7
                )

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(statusText)
    }

    private var statusText: String {
        if session.isConnected {
            return "Connected"
        }

        let value = session.status
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return value.isEmpty
            ? "Disconnected"
            : value
                .replacingOccurrences(
                    of: "_",
                    with: " "
                )
                .capitalized
    }
}
