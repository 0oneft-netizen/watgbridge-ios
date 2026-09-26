import Foundation

enum ReplyPolicy {
    static func mayReply(
        _ message:
            Message
    ) -> Bool {

        !message.deletedRemote
        &&
        !message.messageID
            .isEmpty
    }
}
