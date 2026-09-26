import SwiftUI

struct InboxPriorityMark: View {
    let conversation:
        Conversation

    @ObservedObject
    private var store =
        CustomerWorkflowStore.shared

    var body: some View {
        if store
            .value(
                for:
                    conversation
            )
            .priority {

            Image(
                systemName:
                    "exclamationmark.circle.fill"
            )
            .font(.caption)
            .foregroundStyle(
                .orange
            )
            .accessibilityLabel(
                "Priority"
            )
        }
    }
}
