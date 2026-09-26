import Foundation

enum ReplyPolicy {
    static func mayReply(
        _ message:
            Message
    ) -> Bool {

        !(message.deletedRemote ?? false)
        &&
        !message.messageID
            .isEmpty
    }
}
