import SwiftUI

struct InboxSwipeActions: ViewModifier {
    let conversation:
        Conversation

    @ObservedObject
    private var local =
        ConversationLocalState.shared

    @ObservedObject
    private var workflow =
        CustomerWorkflowStore.shared

    func body(
        content:
            Content
    ) -> some View {

        content
            .swipeActions(
                edge:
                    .trailing,
                allowsFullSwipe:
                    true
            ) {
                Button {
                    local.toggleArchive(
                        conversation
                    )
                } label: {
                    Label(
                        local.isArchived(
                            conversation
                        )
                        ? "Unarchive"
                        : "Archive",
                        systemImage:
                            "archivebox"
                    )
                }

                Button {
                    local.toggleUnread(
                        conversation
                    )
                } label: {
                    Label(
                        "Unread",
                        systemImage:
                            "envelope.badge"
                    )
                }
            }
            .swipeActions(
                edge:
                    .leading,
                allowsFullSwipe:
                    false
            ) {
                Button {
                    workflow.togglePriority(
                        conversation
                    )
                } label: {
                    Label(
                        "Priority",
                        systemImage:
                            "exclamationmark.circle"
                    )
                }
            }
    }
}

extension View {
    func inboxSwipeActions(
        conversation:
            Conversation
    ) -> some View {

        modifier(
            InboxSwipeActions(
                conversation:
                    conversation
            )
        )
    }
}
