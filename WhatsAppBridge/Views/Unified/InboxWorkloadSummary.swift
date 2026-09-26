import SwiftUI

struct InboxWorkloadSummary: View {
    let conversations:
        [Conversation]

    private var snapshot:
        InboxCountSnapshot {
        InboxCounters
            .calculate(
                conversations
            )
    }

    var body: some View {
        HStack(spacing: 8) {
            pill(
                snapshot.unread,
                "Unread"
            )

            pill(
                snapshot.priority,
                "Priority"
            )

            pill(
                snapshot.followUp,
                "Follow Up"
            )
        }
        .padding(
            .horizontal,
            14
        )
    }

    private func pill(
        _ value: Int,
        _ title: String
    ) -> some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .fontWeight(
                    .bold
                )

            Text(title)
        }
        .font(.caption)
        .padding(
            .horizontal,
            9
        )
        .padding(
            .vertical,
            5
        )
        .background(
            Color.secondary
                .opacity(0.08),
            in:
                Capsule()
        )
    }
}
