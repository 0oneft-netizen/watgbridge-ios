import SwiftUI

struct ConversationSwipeActions:
    ViewModifier {

    let conversation: Conversation

    @ObservedObject
    private var state =
        ConversationLocalState.shared

    func body(
        content: Content
    ) -> some View {
        content
            .swipeActions(
                edge: .leading,
                allowsFullSwipe: true
            ) {
                Button {
                    state.toggleUnread(
                        conversation
                    )
                } label: {
                    Label(
                        state.isUnread(
                            conversation
                        )
                        ? "Read"
                        : "Unread",
                        systemImage:
                            state.isUnread(
                                conversation
                            )
                            ? "envelope.open"
                            : "envelope.badge"
                    )
                }

                .tint(.blue)
            }
            .swipeActions(
                edge: .trailing,
                allowsFullSwipe: false
            ) {
                Button {
                    state.toggleArchive(
                        conversation
                    )
                } label: {
                    Label(
                        state.isArchived(
                            conversation
                        )
                        ? "Unarchive"
                        : "Archive",
                        systemImage:
                            "archivebox"
                    )
                }
                .tint(.gray)

                Button {
                    state.togglePin(
                        conversation
                    )
                } label: {
                    Label(
                        state.isPinned(
                            conversation
                        )
                        ? "Unpin"
                        : "Pin",
                        systemImage:
                            "pin"
                    )
                }
                .tint(.orange)

                Button {
                    state.toggleMute(
                        conversation
                    )
                } label: {
                    Label(
                        state.isMuted(
                            conversation
                        )
                        ? "Unmute"
                        : "Mute",
                        systemImage:
                            "speaker.slash"
                    )
                }
                .tint(.indigo)
            }
    }
}

extension View {
    func conversationSwipeActions(
        _ conversation: Conversation
    ) -> some View {
        modifier(
            ConversationSwipeActions(
                conversation:
                    conversation
            )
        )
    }
}
