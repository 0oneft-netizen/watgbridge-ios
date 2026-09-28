import SwiftUI
import UIKit

struct ProductionMessageBubble: View {
    let message: Message
    let messages: [Message]
    var beginsGroup: Bool = true
    var endsGroup: Bool = true

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

        return MessagePresentation
            .fallbackText(
                for: original
            )

    }

    private var hasRenderableMedia: Bool {
        switch message.type {
        case "image", "video", "gif", "video_note", "ptv",
             "voice", "audio", "document",
             "view_once_image", "view_once_video",
             "view_once_audio":
            return true
        default:
            return false
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
                spacing: 2
            ) {
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
            .simultaneousGesture(
                DragGesture(
                    minimumDistance: 18,
                    coordinateSpace: .local
                )
                .onChanged { value in
                    let x =
                        value.translation.width
                    let y =
                        value.translation.height

                    // Vertical scrolling wins. A reply gesture only
                    // becomes active when horizontal intent is obvious.
                    guard abs(x) > 16,
                          abs(x) > abs(y) * 1.25
                    else {
                        dragX = 0
                        return
                    }

                    if message.fromMe {
                        dragX =
                            max(
                                -58,
                                min(0, x)
                            )
                    } else {
                        dragX =
                            min(
                                58,
                                max(0, x)
                            )
                    }
                }
                .onEnded {
                    value in

                    let x =
                        value.translation.width
                    let y =
                        value.translation.height

                    let horizontalIntent =
                        abs(x) > abs(y) * 1.25

                    let shouldReply =
                        horizontalIntent
                        && (
                            message.fromMe
                            ? x < -52
                            : x > 52
                        )

                    withAnimation(
                        .spring(
                            response: 0.25,
                            dampingFraction: 0.8
                        )
                    ) {
                        dragX = 0
                    }

                    if shouldReply {
                        let generator =
                            UIImpactFeedbackGenerator(
                                style: .light
                            )
                        generator.impactOccurred()
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
