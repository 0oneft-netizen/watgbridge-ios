import Foundation

enum MessageMediaPolicy {
    static func isViewOnce(
        _ message: Message
    ) -> Bool {
        switch message.type {
        case "view_once_image",
             "view_once_video",
             "view_once_audio":
            return true

        default:
            return false
        }
    }

    static func mayPersist(
        _ message: Message
    ) -> Bool {
        !isViewOnce(message)
    }

    static func mayShare(
        _ message: Message
    ) -> Bool {
        !isViewOnce(message)
    }

    static func maySave(
        _ message: Message
    ) -> Bool {
        !isViewOnce(message)
    }
}
