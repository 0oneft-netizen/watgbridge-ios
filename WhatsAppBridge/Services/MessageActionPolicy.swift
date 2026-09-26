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
            .mayForward(
                message
            )
    }

    static func mayShare(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .mayShare(
                message
            )
    }

    static func maySave(
        _ message: Message
    ) -> Bool {
        ViewOnceSafety
            .mayPersist(
                message
            )
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
