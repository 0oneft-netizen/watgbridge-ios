import Foundation

enum ConversationExportPolicy {
    static func mayExport(
        _ message: Message
    ) -> Bool {
        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func text(
        messages: [Message]
    ) -> String {
        messages
            .filter(
                mayExport
            )
            .map {
                message in

                let sender =
                    message.fromMe
                    ? "You"
                    : "Customer"

                let time =
                    Date(
                        timeIntervalSince1970:
                            TimeInterval(
                                message.createdAt
                            )
                    )
                    .formatted(
                        date:
                            .abbreviated,
                        time:
                            .shortened
                    )

                let content =
                    message.text
                        .isEmpty
                    ?
                    "["
                    +
                    MessageTypePresentation
                        .label(
                            for:
                                message
                        )
                    +
                    "]"
                    :
                    message.text

                return
                    "\(time) \(sender): \(content)"
            }
            .joined(
                separator: "\n"
            )
    }
}
