import SwiftUI

struct ProductionChatHeader: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var sessionName: String {
        sessions.name(
            for:
                conversation.accountID
                ?? "default"
        )
    }

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

    var body: some View {
        HStack(spacing: 10) {
            avatar

            VStack(
                alignment: .leading,
                spacing: 1
            ) {
                Text(customerName)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(customerPhone)

                    Text("•")

                    Text(sessionName)
                        .fontWeight(.medium)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button {
                // Voice-call routing hooks here.
            } label: {
                Image(
                    systemName: "phone"
                )
            }

            Button {
                // Video-call routing hooks here.
            } label: {
                Image(
                    systemName: "video"
                )
            }
        }
        .task {
            await sessions.refresh()
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    Color.secondary
                        .opacity(0.15)
                )

            Image(
                systemName:
                    "person.fill"
            )
            .foregroundStyle(.secondary)
        }
        .frame(
            width: 36,
            height: 36
        )
    }
}
