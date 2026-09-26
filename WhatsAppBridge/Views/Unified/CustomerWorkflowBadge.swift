import SwiftUI

struct CustomerWorkflowBadge: View {
    let conversation:
        Conversation

    @ObservedObject
    private var store =
        CustomerWorkflowStore.shared

    private var value:
        CustomerWorkflowData {
        store.value(
            for:
                conversation
        )
    }

    var body: some View {
        HStack(spacing: 4) {
            if value.priority {
                Image(
                    systemName:
                        "exclamationmark.circle.fill"
                )
                .foregroundStyle(
                    .orange
                )
            }

            Image(
                systemName:
                    value.stage
                        .systemImage
            )

            Text(
                value.stage.title
            )
        }
        .font(
            .caption2.weight(
                .medium
            )
        )
        .foregroundStyle(
            .secondary
        )
    }
}
