import SwiftUI

struct InboxDraftPreview: View {
    let conversation:
        Conversation

    var body: some View {
        if let text =
            ConversationDraftPreview
                .text(
                    conversation
                ) {

            HStack(spacing: 4) {
                Text("Draft")
                    .foregroundStyle(
                        .red
                    )
                    .fontWeight(
                        .semibold
                    )

                Text(text)
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(1)
            }
            .font(
                .subheadline
            )
        }
    }
}
