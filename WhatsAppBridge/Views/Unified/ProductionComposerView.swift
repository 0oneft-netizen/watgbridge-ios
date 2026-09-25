import SwiftUI

struct ProductionComposerView: View {
    @Binding
    var text: String

    let replyingTo: Message?

    let onCancelReply: () -> Void
    let onAttachment: () -> Void
    let onCamera: () -> Void
    let onSend: () -> Void
    let onVoice: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let replyingTo {
                replyPreview(replyingTo)
            }

            HStack(
                alignment: .bottom,
                spacing: 8
            ) {
                Button(
                    action: onAttachment
                ) {
                    Image(
                        systemName: "plus"
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .medium
                        )
                    )
                }

                HStack(
                    alignment: .bottom,
                    spacing: 8
                ) {
                    TextField(
                        "Message",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(1...6)
                    .padding(
                        .vertical,
                        9
                    )

                    Button(
                        action: onCamera
                    ) {
                        Image(
                            systemName:
                                "camera.fill"
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    .padding(
                        .bottom,
                        9
                    )
                }
                .padding(
                    .horizontal,
                    12
                )
                .background(
                    Color(
                        uiColor:
                            .secondarySystemBackground
                    ),
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )

                Button {
                    if text
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty {
                        onVoice()
                    } else {
                        onSend()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                Color.accentColor
                            )

                        Image(
                            systemName:
                                text
                                    .trimmingCharacters(
                                        in:
                                            .whitespacesAndNewlines
                                    )
                                    .isEmpty
                                ? "mic.fill"
                                : "paperplane.fill"
                        )
                        .foregroundStyle(.white)
                    }
                    .frame(
                        width: 42,
                        height: 42
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
    }

    private func replyPreview(
        _ message: Message
    ) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(
                cornerRadius: 2
            )
            .fill(Color.accentColor)
            .frame(width: 3)

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
                    .caption
                        .weight(.semibold)
                )
                .foregroundStyle(
                    Color.accentColor
                )

                Text(
                    message.text.isEmpty
                    ? message.type
                    : message.text
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                .lineLimit(1)
            }

            Spacer()

            Button(
                action: onCancelReply
            ) {
                Image(
                    systemName:
                        "xmark.circle.fill"
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            7
        )
    }
}
