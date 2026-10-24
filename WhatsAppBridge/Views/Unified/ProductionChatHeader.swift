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
        CustomerAvatarView(jid: conversation.jid, accountID: conversation.accountID, size: AppVisualDesign.chatAvatarSize)
        .frame(
            width:
                AppVisualDesign.chatAvatarSize,
            height:
                AppVisualDesign.chatAvatarSize
        )
        .clipShape(Circle())
    }
}
