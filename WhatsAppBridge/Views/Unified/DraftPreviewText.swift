import SwiftUI

struct DraftPreviewText: View {
    let conversation: Conversation

    private var draft: String {
        ChatDraftStore.shared.text(
            accountID:
                conversation.accountID ?? "default",
            chatJID:
                conversation.jid
        )
    }

    var body: some View {
        if !draft.isEmpty {
            HStack(spacing: 4) {
                Text("Draft")
                    .foregroundStyle(.red)
                    .fontWeight(.semibold)

                Text(draft)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .font(.subheadline)
        }
    }
}
