import SwiftUI

struct UnifiedMessageBubble: View {
    let message: Message
    let senderName: String
    let accountName: String?
    let quotedText: String?

    let onReply: () -> Void
    let onReact: (String) -> Void
    let onDeleteLocal: () -> Void

    private var timestamp: String {
        let raw = message.createdAt

        // Server timestamps may be seconds or milliseconds.
        let seconds: TimeInterval

        if raw > 10_000_000_000 {
            seconds = TimeInterval(raw) / 1000.0
        } else {
            seconds = TimeInterval(raw)
        }

        guard seconds > 0 else {
            return ""
        }

        let date = Date(
            timeIntervalSince1970: seconds
        )

        return date.formatted(
            date: .omitted,
            time: .shortened
        )
    }

    var body: some View {
        HStack(alignment: .bottom) {
            if message.fromMe {
                Spacer(minLength: 45)
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                if !message.fromMe {
                    SenderIdentityPill(
                        name: senderName,
                        accountName: accountName
                    )
                }

                if let quotedText,
                   !quotedText.isEmpty {
                    quotedMessage(quotedText)
                }

                if message.deletedRemote == true {
                    deletedMessage
                } else {
                    content
                }

                HStack(spacing: 4) {
                    Spacer(minLength: 0)

                    Text(timestamp)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    MessageStatusIcon(
                        fromMe: message.fromMe,
                        read: false
                    )
                }

                if let reaction = message.reaction,
                   !reaction.isEmpty {
                    Text(reaction)
                        .font(.system(size: 16))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .offset(y: 9)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .frame(
                maxWidth: ChatDesign.bubbleMaxWidth,
                alignment: .leading
            )
            .background(
                message.fromMe
                ? ChatDesign.outgoingBubble
                : ChatDesign.incomingBubble
            )
            .clipShape(
                ChatBubbleShape(
                    fromMe: message.fromMe
                )
            )
            .contextMenu {
                Button(action: onReply) {
                    Label(
                        "Reply",
                        systemImage:
                            "arrowshape.turn.up.left"
                    )
                }

                Menu("React") {
                    ForEach(
                        ["❤️", "👍", "😂", "😮", "😢", "🙏"],
                        id: \.self
                    ) { emoji in
                        Button(emoji) {
                            onReact(emoji)
                        }
                    }
                }

                if !message.text.isEmpty {
                    Button {
                        UIPasteboard.general.string =
                            message.text
                    } label: {
                        Label(
                            "Copy",
                            systemImage:
                                "doc.on.doc"
                        )
                    }
                }

                Button(
                    role: .destructive,
                    action: onDeleteLocal
                ) {
                    Label(
                        "Delete for Me",
                        systemImage: "trash"
                    )
                }
            }
            .gesture(
                DragGesture(
                    minimumDistance: 25
                )
                .onEnded { value in
                    if value.translation.width > 65 {
                        UIImpactFeedbackGenerator(
                            style: .light
                        ).impactOccurred()

                        onReply()
                    }
                }
            )

            if !message.fromMe {
                Spacer(minLength: 45)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var content: some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            if message.mediaPath != nil ||
                [
                    "image",
                    "video",
                    "video_note",
                    "gif",
                    "voice",
                    "audio",
                    "document",
                    "view_once_image",
                    "view_once_video",
                    "view_once_audio"
                ].contains(message.type) {

                MessageMediaView(
                    message: message
                )
            }

            if !message.text.isEmpty {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
        }
    }

    private func quotedMessage(
        _ value: String
    ) -> some View {
        HStack(spacing: 7) {
            RoundedRectangle(
                cornerRadius: 2
            )
            .fill(ChatDesign.accent)
            .frame(width: 3)

            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(7)
        .background(
            Color.primary.opacity(0.055)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 7
            )
        )
    }

    private var deletedMessage: some View {
        Label(
            "This message was deleted",
            systemImage: "nosign"
        )
        .font(.subheadline.italic())
        .foregroundStyle(.secondary)
    }
}
