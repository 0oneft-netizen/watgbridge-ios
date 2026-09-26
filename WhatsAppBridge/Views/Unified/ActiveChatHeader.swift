import SwiftUI

struct ActiveChatHeader: View {
    let conversation:
        Conversation

    let openProfile:
        () -> Void

    var body: some View {
        Button(
            action:
                openProfile
        ) {
            HStack(spacing: 9) {
                CustomerAvatarView(
                    jid:
                        conversation.jid
                )
                .frame(
                    width: 36,
                    height: 36
                )

                CustomerRouteLabel(
                    conversation:
                        conversation
                )

                Spacer()
            }
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
    }
}
