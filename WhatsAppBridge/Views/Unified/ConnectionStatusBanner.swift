import SwiftUI

struct ConnectionStatusBanner: View {
    let connected: Bool
    let text: String?

    var body: some View {
        if !connected {
            HStack(spacing: 8) {
                Image(
                    systemName:
                        "wifi.slash"
                )

                Text(
                    text
                    ?? "Connection unavailable"
                )
                .font(
                    .caption.weight(
                        .semibold
                    )
                )

                Spacer()
            }
            .foregroundStyle(
                .primary
            )
            .padding(
                .horizontal,
                14
            )
            .frame(height: 36)
            .background(
                Color.orange
                    .opacity(0.15)
            )
        }
    }
}
