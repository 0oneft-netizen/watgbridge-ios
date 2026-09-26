import Foundation

enum ChatMemoryPolicy {
    static let softLimit =
        800

    static let hardLimit =
        1_500

    static func trim(
        _ messages: [Message],
        keepAround messageID:
            Int64? = nil
    ) -> [Message] {
        guard
            messages.count >
                hardLimit
        else {
            return messages
        }

        guard
            let messageID,
            let index =
                messages.firstIndex(
                    where: {
                        $0.id ==
                            messageID
                    }
                )
        else {
            return Array(
                messages.suffix(
                    softLimit
                )
            )
        }

        let half =
            softLimit / 2

        let start =
            max(
                0,
                index - half
            )

        let end =
            min(
                messages.count,
                start
                + softLimit
            )

        return Array(
            messages[
                start..<end
            ]
        )
    }
}
