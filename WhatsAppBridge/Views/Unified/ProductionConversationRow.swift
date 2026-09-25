import SwiftUI

struct ProductionConversationRow: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var customerName: String {
        ChatIdentity.customerName(
            conversation: conversation
        )
    }

    private var customerPhone: String {
        ChatIdentity.customerPhone(
            from: conversation.jid
        )
    }

    private var sessionName: String {
        sessions.name(
            for:
                conversation.accountID
                ?? "default"
        )
    }

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            ZStack {
                Circle()
                    .fill(
                        Color.secondary
                            .opacity(0.12)
                    )

                Image(
                    systemName:
                        "person.fill"
                )
                .font(.title3)
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                width: 52,
                height: 52
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                HStack {
                    Text(customerName)
                        .font(
                            .body
                                .weight(
                                    .semibold
                                )
                        )
                        .lineLimit(1)

                    Spacer()

                    if conversation.unread > 0 {
                        UnreadBadge(
                            count:
                                conversation.unread
                        )
                    }
                }

                HStack(spacing: 4) {
                    Text(customerPhone)

                    Text("•")

                    Text(sessionName)
                        .fontWeight(
                            .medium
                        )
                }
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(1)

                Text(
                    conversation.lastMessage
                )
                .font(.subheadline)
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(1)
            }
        }
        .padding(
            .vertical,
            5
        )
        .task {
            if sessions.sessions.isEmpty {
                await sessions.refresh()
            }
        }
    }
}
