import Foundation

enum MessagePreviewText {
    static func value(
        _ message: Message
    ) -> String {
        if message.deletedRemote {
            return "Message deleted"
        }

        if !message.text
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty {

            return message.text
                .replacingOccurrences(
                    of: "\n",
                    with: " "
                )
        }

        return MessageTypePresentation
            .label(
                for:
                    message
            )
    }
}
