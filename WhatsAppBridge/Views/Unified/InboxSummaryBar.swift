import SwiftUI

struct InboxSummaryBar: View {
    let conversations:
        [Conversation]

    private var counts:
        InboxCountSnapshot {
        InboxCounters
            .calculate(
                conversations
            )
    }

    var body: some View {
        HStack(spacing: 0) {
            value(
                counts.unread,
                "Unread"
            )

            value(
                counts.priority,
                "Priority"
            )

            value(
                counts.followUp,
                "Follow Up"
            )
        }
        .padding(
            .vertical,
            7
        )
    }

    private func value(
        _ count: Int,
        _ title: String
    ) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(
                    .subheadline
                        .bold()
                )

            Text(title)
                .font(
                    .caption2
                )
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth:
                .infinity
        )
    }
}
