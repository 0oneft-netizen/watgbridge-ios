import Foundation

enum MediaOperationPolicy {
    static func mayDownload(
        _ message:
            Message
    ) -> Bool {

        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func mayCache(
        _ message:
            Message
    ) -> Bool {

        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func maySave(
        _ message:
            Message
    ) -> Bool {

        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func mayShare(
        _ message:
            Message
    ) -> Bool {

        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }

    static func mayForward(
        _ message:
            Message
    ) -> Bool {

        !MessageMediaPolicy
            .isViewOnce(
                message
            )
    }
}
