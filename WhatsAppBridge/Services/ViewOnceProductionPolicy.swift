import Foundation

enum ViewOnceProductionPolicy {
    static func isProtected(
        _ message: Message
    ) -> Bool {

        MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func mayPersist(
        _ message: Message
    ) -> Bool {

        !isProtected(message)
    }

    static func mayCache(
        _ message: Message
    ) -> Bool {

        !isProtected(message)
    }

    static func mayExport(
        _ message: Message
    ) -> Bool {

        !isProtected(message)
    }

    static func mayShare(
        _ message: Message
    ) -> Bool {

        !isProtected(message)
    }

    static func mayForward(
        _ message: Message
    ) -> Bool {

        !isProtected(message)
    }

    static func maySave(
        _ message: Message
    ) -> Bool {

        !isProtected(message)
    }
}
