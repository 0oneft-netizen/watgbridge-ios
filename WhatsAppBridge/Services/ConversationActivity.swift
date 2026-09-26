import Foundation

struct ConversationActivitySnapshot:
    Equatable {

    let firstMessage:
        Date?

    let lastMessage:
        Date?

    let incoming:
        Int

    let outgoing:
        Int

    let media:
        Int
}

enum ConversationActivity {
    static func snapshot(
        messages: [Message]
    ) -> ConversationActivitySnapshot {

        let sorted =
            messages.sorted {
                $0.createdAt <
                    $1.createdAt
            }

        return
            ConversationActivitySnapshot(
                firstMessage:
                    sorted.first.map {
                        Date(
                            timeIntervalSince1970:
                                TimeInterval(
                                    $0.createdAt
                                )
                        )
                    },

                lastMessage:
                    sorted.last.map {
                        Date(
                            timeIntervalSince1970:
                                TimeInterval(
                                    $0.createdAt
                                )
                        )
                    },

                incoming:
                    messages.filter {
                        !$0.fromMe
                    }.count,

                outgoing:
                    messages.filter {
                        $0.fromMe
                    }.count,

                media:
                    messages.filter {
                        MessageMediaPolicy
                            .isRenderableMedia(
                                $0
                            )
                        &&
                        !MessageMediaPolicy
                            .isViewOnce(
                                $0
                            )
                    }.count
            )
    }
}
