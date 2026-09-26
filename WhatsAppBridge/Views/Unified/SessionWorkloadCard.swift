import SwiftUI

struct SessionWorkloadCard: View {
    let name: String
    let workload:
        SessionWorkload

    var body: some View {
        VStack(
            alignment:
                .leading,
            spacing: 10
        ) {
            Text(name)
                .font(
                    .headline
                )

            HStack {
                metric(
                    workload
                        .conversations,
                    "Chats"
                )

                metric(
                    workload
                        .unread,
                    "Unread"
                )

                metric(
                    workload
                        .priority,
                    "Priority"
                )

                metric(
                    workload
                        .followUps,
                    "Follow Up"
                )
            }
        }
        .padding(14)
        .background(
            Color.secondary
                .opacity(0.07),
            in:
                RoundedRectangle(
                    cornerRadius: 14
                )
        )
    }

    private func metric(
        _ value: Int,
        _ title: String
    ) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
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
