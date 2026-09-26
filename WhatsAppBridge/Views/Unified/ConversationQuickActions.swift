import SwiftUI

struct ConversationQuickActions: View {
    let conversation: Conversation

    @ObservedObject
    private var state = ConversationLocalState.shared

    var body: some View {
        Menu {
            Button {
                state.togglePin(conversation)
            } label: {
                Label(
                    state.isPinned(conversation) ? "Unpin" : "Pin",
                    systemImage: state.isPinned(conversation)
                        ? "pin.slash"
                        : "pin"
                )
            }

            Button {
                state.toggleUnread(conversation)
            } label: {
                Label(
                    state.isUnread(conversation)
                        ? "Mark as read"
                        : "Mark as unread",
                    systemImage: "envelope.badge"
                )
            }

            Button {
                state.toggleMute(conversation)
            } label: {
                Label(
                    state.isMuted(conversation) ? "Unmute" : "Mute",
                    systemImage: state.isMuted(conversation)
                        ? "speaker.wave.2"
                        : "speaker.slash"
                )
            }

            Button {
                state.toggleArchive(conversation)
            } label: {
                Label(
                    state.isArchived(conversation)
                        ? "Unarchive"
                        : "Archive",
                    systemImage: "archivebox"
                )
            }
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 34, height: 34)
        }
    }
}
