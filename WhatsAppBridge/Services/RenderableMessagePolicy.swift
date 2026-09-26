import Foundation

enum RenderableMessagePolicy {
    static func hasMedia(
        _ message:
            Message
    ) -> Bool {

        switch message.type
            .lowercased() {

        case "image",
             "video",
             "gif",
             "video_note",
             "voice",
             "audio",
             "document",
             "view_once_image",
             "view_once_video",
             "view_once_audio":

            return true

        default:
            return false
        }
    }

    static func hasText(
        _ message:
            Message
    ) -> Bool {

        !message.text
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty
    }

    static func isRenderable(
        _ message:
            Message
    ) -> Bool {

        hasText(message)
        ||
        hasMedia(message)
        ||
        message.deletedRemote
    }
}
