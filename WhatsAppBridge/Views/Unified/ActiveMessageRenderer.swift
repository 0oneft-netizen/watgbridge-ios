import SwiftUI

struct ActiveMessageRenderer: View {
    let message:
        Message

    let previous:
        Message?

    let next:
        Message?

    let reply:
        (Message) -> Void

    let forward:
        (Message) -> Void

    let react:
        (Message) -> Void

    let delete:
        (Message) -> Void

    var body: some View {
        VStack(spacing: 4) {
            if ChatDateSectionPolicy
                .needsSeparator(
                    previous:
                        previous,
                    current:
                        message
                ) {

                ChatDateChip(
                    timestamp:
                        message.createdAt
                )
            }

            if RenderableMessagePolicy
                .isRenderable(
                    message
                ) {

                ProductionMessageBubble(
                    message:
                        message,
                    beginsGroup:
                        MessageGrouping
                            .beginsGroup(
                                previous:
                                    previous,
                                current:
                                    message
                            ),
                    endsGroup:
                        MessageGrouping
                            .endsGroup(
                                current:
                                    message,
                                next:
                                    next
                            ),
                    onReply: {
                        reply(message)
                    }
                )
                .contextMenu {
                    MessageActionMenu(
                        message:
                            message,
                        reply: {
                            reply(message)
                        },
                        forward: {
                            forward(message)
                        },
                        react: {
                            react(message)
                        },
                        delete: {
                            delete(message)
                        }
                    )
                }

            } else {
                UnsupportedMessageView(
                    message:
                        message
                )
            }
        }
    }
}
