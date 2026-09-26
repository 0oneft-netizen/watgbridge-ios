import SwiftUI

struct FollowUpBadge: View {
    let conversation:
        Conversation

    @ObservedObject
    private var store =
        CustomerFollowUpStore.shared

    var body: some View {
        if let item =
            store.value(
                for:
                    conversation
            ),
           !item.completed {

            HStack(spacing: 4) {
                Image(
                    systemName:
                        store.isDue(
                            conversation
                        )
                        ? "bell.badge.fill"
                        : "bell"
                )

                Text(
                    item.dueAt
                        .formatted(
                            date:
                                .omitted,
                            time:
                                .shortened
                        )
                )
            }
            .font(
                .caption2.weight(
                    .semibold
                )
            )
            .foregroundStyle(
                store.isDue(
                    conversation
                )
                ? Color.orange
                : Color.secondary
            )
        }
    }
}
