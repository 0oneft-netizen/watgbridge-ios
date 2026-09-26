import Foundation

enum ReplyTargetResolver {
    static func message(
        for replyID: String?,
        in messages: [Message]
    ) -> Message? {
        guard
            let replyID,
            !replyID.isEmpty
        else {
            return nil
        }

        return messages.first {
            $0.messageID == replyID
        }
    }
}
