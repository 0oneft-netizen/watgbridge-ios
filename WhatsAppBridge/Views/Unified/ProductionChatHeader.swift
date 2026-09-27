import SwiftUI

struct ProductionChatHeader: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

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

                SessionMiniBadge(
                    name: sessionName
                )
            }

            Spacer(minLength: 2)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .contentShape(Rectangle())
        .accessibilityElement(
            children: .combine
        )
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
                AppAvatarPlaceholder(
                    initials:
                        conversation.initials,
                    size:
                        AppVisualDesign
                            .chatAvatarSize
                )
            }
        }
        .frame(
            width:
                AppVisualDesign.chatAvatarSize,
            height:
                AppVisualDesign.chatAvatarSize
        )
        .clipShape(Circle())
    }
}
