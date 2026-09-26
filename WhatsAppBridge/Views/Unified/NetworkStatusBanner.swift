import SwiftUI

struct NetworkStatusBanner: View {
    @ObservedObject
    private var network =
        NetworkMonitor.shared

    var body: some View {
        if !network.isConnected {
            HStack(spacing: 8) {
                Image(
                    systemName:
                        "wifi.slash"
                )

                Text(
                    "Waiting for network…"
                )
                .font(
                    .caption.bold()
                )

                Spacer()

                ProgressView()
                    .controlSize(
                        .small
                    )
            }
            .padding(
                .horizontal,
                14
            )
            .frame(height: 36)
            .background(
                Color.orange
                    .opacity(0.16)
            )
        }
    }
}
