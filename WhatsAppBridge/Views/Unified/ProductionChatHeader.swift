import SwiftUI

struct ProductionChatHeader: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions = SessionDirectory.shared

    private var sessionName: String {
        sessions.name(
            for: conversation.accountID
        )
    }

    private var customerName: String {
        ChatIdentity.customerName(
            conversation: conversation
        )
    }

    var body: some View {
        HStack(spacing: 9) {
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

                HStack(spacing: 5) {
                    Circle()
                        .fill(ChatDesign.accent)
                        .frame(
                            width: 5,
                            height: 5
                        )

                    Text(sessionName)
                        .font(
                            .system(
                                size: 11.5,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(customerName), \(sessionName)"
        )
        .task {
            if sessions.sessions.isEmpty {
                await sessions.refresh()
            }
        }
    }

    private var avatar: some View {
        AsyncImage(
            url: APIClient.shared.avatarURL(
                for: conversation.jid
            )
        ) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()

            default:
                avatarFallback
            }
        }
        .frame(
            width: 40,
            height: 40
        )
        .clipShape(Circle())
    }

    private var avatarFallback: some View {
        ZStack {
            Circle()
                .fill(
                    Color.secondary
                        .opacity(0.14)
                )

            Text(conversation.initials)
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)
        }
    }
}
