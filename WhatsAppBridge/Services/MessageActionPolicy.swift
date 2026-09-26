import Foundation

enum MessageActionPolicy {
    static func canCopy(
        _ message: Message
    ) -> Bool {
        !message.text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
        && message.deletedRemote != true
    }

    static func canReply(
        _ message: Message
    ) -> Bool {
        message.deletedRemote != true
    }

    static func canReact(
        _ message: Message
    ) -> Bool {
        message.deletedRemote != true
    }

    static func canDeleteForEveryone(
        _ message: Message
    ) -> Bool {
        message.fromMe
        && message.deletedRemote != true
    }
}
