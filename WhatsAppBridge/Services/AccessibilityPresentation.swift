import Foundation

enum AccessibilityPresentation {
    static func messageLabel(
        _ message:
            Message
    ) -> String {

        var values:
            [String] = []

        values.append(
            message.fromMe
            ? "Outgoing"
            : "Incoming"
        )

        if !message.text.isEmpty {
            values.append(
                MessageContentPolicy
                    .preview(
                        message.text
                    )
            )
        } else {
            values.append(
                MediaTypePresentation
                    .title(
                        message
                    )
            )
        }

        values.append(
            MessageTimestampPresentation
                .time(
                    message.createdAt
                )
        )

        return values.joined(
            separator:
                ", "
        )
    }
}
