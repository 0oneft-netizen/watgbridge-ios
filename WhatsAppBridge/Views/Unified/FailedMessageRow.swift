import SwiftUI

struct FailedMessageRow: View {
    let message:
        OutboxTextMessage

    let retry:
        () -> Void

    var body: some View {
        HStack(
            alignment: .bottom,
            spacing: 8
        ) {
            Spacer(
                minLength: 55
            )

            VStack(
                alignment:
                    .trailing,
                spacing: 4
            ) {
                Text(
                    message.text
                )
                .font(.body)
                .textSelection(
                    .enabled
                )

                HStack(spacing: 5) {
                    Image(
                        systemName:
                            "exclamationmark.circle.fill"
                    )
                    .foregroundStyle(
                        .red
                    )

                    Text(
                        "Not sent"
                    )
                    .font(
                        .caption2
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .padding(10)
            .background(
                Color.secondary
                    .opacity(0.10),
                in:
                    RoundedRectangle(
                        cornerRadius: 12
                    )
            )

            Button(
                action: retry
            ) {
                Image(
                    systemName:
                        "arrow.clockwise"
                )
            }
            .buttonStyle(
                .borderless
            )
        }
        .padding(
            .horizontal,
            10
        )
    }
}
