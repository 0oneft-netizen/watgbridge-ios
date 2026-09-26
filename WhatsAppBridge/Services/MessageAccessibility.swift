import Foundation

enum MessageAccessibility {
    static func label(
        _ message: Message
    ) -> String {
        let sender =
            message.fromMe
            ? "You"
            : "Customer"

        let content =
            MessagePreviewText
                .value(
                    message
                )

        let time =
            MessageTimestampFormatter
                .string(
                    message.createdAt
                )

        return
            "\(sender), \(content), \(time)"
    }
}
