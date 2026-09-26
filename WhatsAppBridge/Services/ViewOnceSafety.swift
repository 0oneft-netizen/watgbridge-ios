import Foundation

enum ViewOnceSafety {
    static func mayPersist(
        _ message: Message
    ) -> Bool {
        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func mayShare(
        _ message: Message
    ) -> Bool {
        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func mayForward(
        _ message: Message
    ) -> Bool {
        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func mayExport(
        _ message: Message
    ) -> Bool {
        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }
}
