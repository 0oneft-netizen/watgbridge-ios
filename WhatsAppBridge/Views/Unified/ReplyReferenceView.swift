import SwiftUI

struct ReplyReferenceView: View {
    let message: Message
    let action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 8) {
                RoundedRectangle(
                    cornerRadius: 2
                )
                .frame(
                    width: 3,
                    height: 34
                )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(
                        message.fromMe
                        ? "You"
                        : "Reply"
                    )
                    .font(
                        .caption.bold()
                    )

                    HStack(spacing: 5) {
                        Image(
                            systemName:
                                MessageTypePresentation
                                    .icon(
                                        for: message
                                    )
                        )
                        .font(.caption2)

                        Text(
                            MessageTypePresentation
                                .label(
                                    for: message
                                )
                        )
                        .font(.caption)
                        .lineLimit(1)
                    }
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer(
                    minLength: 0
                )
            }
            .padding(8)
            .background(
                Color.secondary
                    .opacity(0.08),
                in:
                    RoundedRectangle(
                        cornerRadius: 8
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
