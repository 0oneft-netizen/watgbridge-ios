import SwiftUI

struct ConversationStatusBadges: View {
    let conversation: Conversation

    @ObservedObject
    private var state = ConversationLocalState.shared

    var body: some View {
        HStack(spacing: 6) {
            if state.isPinned(conversation) {
                Image(systemName: "pin.fill")
            }

            if state.isMuted(conversation) {
                Image(systemName: "speaker.slash.fill")
            }

            if state.isUnread(conversation) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}
