import SwiftUI

struct ProductionMessageBubble: View {
    let message: Message
    let messages: [Message]

    let onReply: () -> Void
    let onReact: (String) -> Void
    let onDelete: () -> Void

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    @State
    private var dragX: CGFloat = 0

    private var sender: String {
        if message.fromMe {
            return "You"
        }

        let value = message.senderJID

        guard let at =
            value.firstIndex(of: "@")
        else {
            return value
        }

        return String(value[..<at])
    }

    private var sessionName: String {
        sessions.name(
            for: message.accountID
        )
    }

    private var quotedText: String? {
        guard
            let replyID = message.replyToID,
            !replyID.isEmpty
        else {
            return nil
        }

        guard let original =
            messages.first(
                where: {
                    $0.messageID == replyID
                }
            )
        else {
            return "Reply"
        }

        if !original.text.isEmpty {
            return original.text
        }

        switch original.type {
        case "image":
            return "Photo"

        case "video":
            return "Video"

        case "video_note":
            return "Video message"

        case "voice":
            return "Voice message"

        case "audio":
            return "Audio"

        case "document":
            return original.fileName
                ?? "Document"

        default:
            return "Message"
        }
    }

    var body: some View {
        HStack {
            if message.fromMe {
                Spacer(
                    minLength: 46
                )
            }

            VStack(
                alignment:
                    message.fromMe
                    ? .trailing
                    : .leading,
                spacing: 3
            ) {
                SessionRouteBadge(
                    name: sessionName
                )

                UnifiedMessageBubble(
                    message: message,
                    senderName: sender,
                    accountName:
                        sessionName,
                    quotedText:
                        quotedText,
                    onReply:
                        onReply,
                    onReact:
                        onReact,
                    onDeleteLocal:
                        onDelete
                )
            }
            .offset(
                x: message.fromMe
                    ? min(0, dragX)
                    : max(0, dragX)
            )
            .gesture(
                DragGesture(
                    minimumDistance: 12
                )
                .onChanged {
                    value in

                    let amount =
                        value.translation.width

                    if message.fromMe {
                        dragX =
                            max(
                                -80,
                                min(
                                    0,
                                    amount
                                )
                            )
                    } else {
                        dragX =
                            min(
                                80,
                                max(
                                    0,
                                    amount
                                )
                            )
                    }
                }
                .onEnded {
                    value in

                    let amount =
                        value.translation.width

                    let shouldReply =
                        message.fromMe
                        ? amount < -55
                        : amount > 55

                    withAnimation(
                        .spring(
                            response: 0.25,
                            dampingFraction: 0.8
                        )
                    ) {
                        dragX = 0
                    }

                    if shouldReply {
                        onReply()
                    }
                }
            )

            if !message.fromMe {
                Spacer(
                    minLength: 46
                )
            }
        }
        .task {
            if sessions.sessions.isEmpty {
                await sessions.refresh()
            }
        }
    }
}
