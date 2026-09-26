import Foundation

enum DeleteMessagePolicy {
    static func mayDeleteLocally(
        _ message:
            Message
    ) -> Bool {
        true
    }

    static func mayDeleteForEveryone(
        _ message:
            Message
    ) -> Bool {

        message.fromMe
        &&
        !message.deletedRemote
        &&
        !message.messageID
            .isEmpty
    }
}
