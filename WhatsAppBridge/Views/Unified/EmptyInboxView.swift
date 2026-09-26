import SwiftUI

struct EmptyInboxView: View {
    var body: some View {
        ContentUnavailableView {
            Label(
                "No conversations yet",
                systemImage:
                    "message.badge.waveform"
            )
        } description: {
            Text(
                "Messages from your connected accounts will appear here."
            )
        }
    }
}
