import Foundation

enum MessageActionPolicy {
    static func mayCopy(
        _ message: Message
    ) -> Bool {
        !message.text
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty
    }

    static func mayForward(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .mayForward(message)
        &&
        !(message.deletedRemote ?? false)
    }

    static func mayShare(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .mayShare(message)
        &&
        !(message.deletedRemote ?? false)
    }

    static func maySave(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .maySave(message)
        &&
        !(message.deletedRemote ?? false)
    }

    static func mayReact(
        _ message: Message
    ) -> Bool {
        !(message.deletedRemote ?? false)
    }

    static func mayReply(
        _ message: Message
    ) -> Bool {
        !(message.deletedRemote ?? false)
    }
}
