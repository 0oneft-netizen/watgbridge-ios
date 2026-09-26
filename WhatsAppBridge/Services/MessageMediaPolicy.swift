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


    static func isRenderableMedia(
        _ message: Message
    ) -> Bool {
        if isViewOnce(message) {
            return true
        }

        let type =
            message.type.lowercased()

        let supported:
            Set<String> = [
                "image",
                "video",
                "gif",
                "video_note",
                "ptv",
                "voice",
                "audio",
                "document",
                "sticker"
            ]

        if supported.contains(type) {
            return true
        }

        if let path =
            message.mediaPath,
           !path.isEmpty {
            return true
        }

        return false
    }
}
