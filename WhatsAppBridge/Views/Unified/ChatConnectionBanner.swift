import SwiftUI

struct ChatConnectionBanner: View {
    let status: String

    private var visible: Bool {
        status != "connected"
    }

    var body: some View {
        if visible {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)

                Text(label)
                    .font(
                        .caption.weight(
                            .medium
                        )
                    )

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Color.orange.opacity(
                    0.14
                )
            )
        }
    }

    private var label: String {
        switch status {
        case "reconnect_required":
            return "WhatsApp needs to be reconnected"

        case "disconnected":
            return "Waiting for connection…"

        default:
            return "Connecting…"
        }
    }
}
