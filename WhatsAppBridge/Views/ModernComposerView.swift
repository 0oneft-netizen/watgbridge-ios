import SwiftUI

struct ModernComposerView: View {
    @Binding var text: String

    var replyingTo: String?
    var destination: String?

    let onSend: () -> Void
    let onAttachment: () -> Void
    let onCamera: () -> Void
    let onVoice: () -> Void
    let onCancelReply: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let replyingTo,
               !replyingTo.isEmpty {
                replyPreview(replyingTo)
            }

            if let destination,
               !destination.isEmpty {
                destinationBar(destination)
            }

            HStack(alignment: .bottom, spacing: 8) {
                Button(action: onAttachment) {
                    Image(systemName: "plus")
                        .font(.system(
                            size: 21,
                            weight: .medium
                        ))
                        .frame(
                            width: 34,
                            height: 34
                        )
                }

                HStack(alignment: .bottom, spacing: 8) {
                    TextField(
                        "Message",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(1...6)
                    .padding(.leading, 12)
                    .padding(.vertical, 8)

                    Button(action: onCamera) {
                        Image(
                            systemName: "camera.fill"
                        )
                        .foregroundStyle(.secondary)
                        .frame(
                            width: 30,
                            height: 34
                        )
                    }
                    .padding(.trailing, 3)
                }
                .background(
                    Color(
                        uiColor:
                            .secondarySystemBackground
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                )

                if text.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty {
                    Button(action: onVoice) {
                        Image(
                            systemName:
                                "mic.fill"
                        )
                        .foregroundStyle(.white)
                        .frame(
                            width: 38,
                            height: 38
                        )
                        .background(
                            ChatDesign.accent
                        )
                        .clipShape(Circle())
                    }
                } else {
                    Button(action: onSend) {
                        Image(
                            systemName:
                                "paperplane.fill"
                        )
                        .foregroundStyle(.white)
                        .frame(
                            width: 38,
                            height: 38
                        )
                        .background(
                            ChatDesign.accent
                        )
                        .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
        }
        .background(.bar)
    }

    private func replyPreview(
        _ value: String
    ) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(
                cornerRadius: 2
            )
            .fill(ChatDesign.accent)
            .frame(width: 4)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Replying")
                    .font(
                        .caption.weight(.semibold)
                    )
                    .foregroundStyle(
                        ChatDesign.accent
                    )

                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onCancelReply) {
                Image(
                    systemName:
                        "xmark.circle.fill"
                )
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Color(
                uiColor:
                    .secondarySystemBackground
            )
        )
    }

    private func destinationBar(
        _ value: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(
                systemName:
                    "arrowshape.turn.up.right.fill"
            )
            .font(.caption2)
            .foregroundStyle(
                ChatDesign.accent
            )

            Text("Reply via")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(
                    .caption2.weight(.semibold)
                )
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }
}
