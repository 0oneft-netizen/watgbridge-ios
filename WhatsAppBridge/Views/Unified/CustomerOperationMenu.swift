import SwiftUI

struct CustomerOperationMenu: View {
    let conversation:
        Conversation

    @ObservedObject
    private var workflow =
        CustomerWorkflowStore.shared

    @ObservedObject
    private var localState =
        ConversationLocalState.shared

    var body: some View {
        Menu {
            Button {
                localState
                    .toggleUnread(
                        conversation
                    )
            } label: {
                Label(
                    localState
                        .isUnread(
                            conversation
                        )
                    ? "Mark Read"
                    : "Mark Unread",
                    systemImage:
                        "envelope"
                )
            }

            Button {
                workflow
                    .togglePriority(
                        conversation
                    )
            } label: {
                Label(
                    workflow
                        .value(
                            for:
                                conversation
                        )
                        .priority
                    ? "Remove Priority"
                    : "Priority",
                    systemImage:
                        "exclamationmark.circle"
                )
            }

            Button {
                workflow
                    .setStage(
                        .done,
                        for:
                            conversation
                    )
            } label: {
                Label(
                    "Mark Done",
                    systemImage:
                        "checkmark.circle"
                )
            }

            Divider()

            Button {
                localState
                    .toggleArchive(
                        conversation
                    )
            } label: {
                Label(
                    localState
                        .isArchived(
                            conversation
                        )
                    ? "Unarchive"
                    : "Archive",
                    systemImage:
                        "archivebox"
                )
            }
        } label: {
            Image(
                systemName:
                    "ellipsis.circle"
            )
        }
    }
}
