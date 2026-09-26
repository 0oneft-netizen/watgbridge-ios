import SwiftUI

struct CustomerConversationStats: View {
    let messages: [Message]

    private var incoming:
        Int {
        messages.filter {
            !$0.fromMe
        }.count
    }

    private var outgoing:
        Int {
        messages.filter {
            $0.fromMe
        }.count
    }

    private var media:
        Int {
        messages.filter {
            MessageMediaPolicy
                .isRenderableMedia(
                    $0
                )
            &&
            !MessageMediaPolicy
                .isViewOnce($0)
        }.count
    }

    var body: some View {
        HStack(spacing: 0) {
            stat(
                "\(incoming)",
                "Received"
            )

            Divider()
                .frame(height: 32)

            stat(
                "\(outgoing)",
                "Sent"
            )

            Divider()
                .frame(height: 32)

            stat(
                "\(media)",
                "Media"
            )
        }
        .frame(
            maxWidth:
                .infinity
        )
        .padding(
            .vertical,
            8
        )
    }

    private func stat(
        _ value: String,
        _ label: String
    ) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(
                    .headline
                )

            Text(label)
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
