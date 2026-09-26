import Foundation

enum MessageMediaPolicy {
    static func isViewOnce(
        _ message: Message
    ) -> Bool {
        let type = message.type
            .lowercased()
            .replacingOccurrences(
                of: "-",
                with: "_"
            )

        return type == "view_once"
            || type == "view_once_image"
            || type == "view_once_video"
            || type.contains("viewonce")
    }

    static func mayPersist(
        _ message: Message
    ) -> Bool {
        !isViewOnce(message)
    }

    static func mayCache(
        _ message: Message
    ) -> Bool {
        !isViewOnce(message)
    }

    static func maySave(
        _ message: Message
    ) -> Bool {
        !isViewOnce(message)
    }

    static func mayShare(
        _ message: Message
    ) -> Bool {
        !isViewOnce(message)
    }

    static func mayExport(
        _ message: Message
    ) -> Bool {
        !isViewOnce(message)
    }
}
