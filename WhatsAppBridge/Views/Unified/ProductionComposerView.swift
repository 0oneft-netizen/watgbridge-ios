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

    private var hasText: Bool {
        !text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if let replyingTo {
                replyPreview(replyingTo)
            }

            HStack(
                alignment: .bottom,
                spacing: 7
            ) {
                Button(
                    action: onAttachment
                ) {
                    Image(systemName: "plus")
                        .font(
                            .system(
                                size: 23,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            Color.accentColor
                        )
                        .frame(
                            width: 34,
                            height: 38
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
                    .submitLabel(.send)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                    .padding(.leading, 3)
                    .padding(.vertical, 9)

                    Button(
                        action: onCamera
                    ) {
                        Image(
                            systemName:
                                "camera.fill"
                        )
                        .font(.system(size: 17))
                        .foregroundStyle(
                            Color.accentColor
                        )
                    }
                    .padding(.trailing, 2)
                    .padding(.bottom, 10)
                }
                .padding(.horizontal, 10)
                .background(
                    AppVisualDesign
                        .composerField,
                    in: RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                    .stroke(
                        Color.secondary
                            .opacity(0.12),
                        lineWidth: 0.5
                    )
                }

                Button {
                    if hasText {
                        onSend()
                    } else {
                        onVoice()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                Color.accentColor
                            )

                        Image(
                            systemName:
                                hasText
                                ? "paperplane.fill"
                                : "mic.fill"
                        )
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                    }
                    .frame(
                        width: 40,
                        height: 40
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 5)
            .padding(.bottom, 7)
            .animation(
                .easeInOut(duration: 0.15),
                value: hasText
            )
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
                .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}
