import Foundation

enum ProfileMediaPolicy {
    static func mayDisplay(
        _ message: Message
    ) -> Bool {
        guard
            !MessageMediaPolicy
                .isViewOnce(
                    message
                )
        else {
            return false
        }

        return MessageMediaPolicy
            .isRenderableMedia(
                message
            )
    }

    static func maySave(
        _ message: Message
    ) -> Bool {
        MessageMediaPolicy
            .maySave(
                message
            )
    }
}
