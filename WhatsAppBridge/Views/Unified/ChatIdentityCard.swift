import SwiftUI

struct ChatIdentityCard: View {
    let conversation:
        Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    var body: some View {
        HStack(spacing: 10) {
            CustomerAvatarView(
                jid:
                    conversation.jid
            )
            .frame(
                width: 44,
                height: 44
            )

            VStack(
                alignment:
                    .leading,
                spacing: 3
            ) {
                Text(
                    CustomerIdentityPresentation
                        .title(
                            conversation:
                                conversation
                        )
                )
                .font(
                    .headline
                )

                Text(
                    sessions.name(
                        for:
                            conversation
                                .accountID
                            ?? "default"
                    )
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
            }

            Spacer()
        }
    }
}
