import SwiftUI

struct ProductionChatStatusStrip: View {
    let conversation:
        Conversation

    @ObservedObject
    private var network =
        NetworkMonitor.shared

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    var body: some View {
        if !network.isConnected {
            NetworkStatusBanner()

        } else if !sessionConnected {
            HStack(spacing: 7) {
                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )

                Text(
                    "This WhatsApp account is not connected"
                )
                .font(
                    .caption.bold()
                )

                Spacer()
            }
            .padding(
                .horizontal,
                14
            )
            .frame(height: 34)
            .background(
                Color.orange
                    .opacity(0.15)
            )
        }
    }

    private var sessionConnected:
        Bool {

        let accountID =
            conversation.accountID
            ?? "default"

        guard
            let account =
                sessions.accounts
                    .first(
                        where: {
                            $0.id ==
                                accountID
                        }
                    )
        else {
            return true
        }

        return account.status
            .lowercased()
            ==
            "connected"
    }
}
