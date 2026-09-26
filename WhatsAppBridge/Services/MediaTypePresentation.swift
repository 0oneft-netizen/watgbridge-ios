import Foundation

enum MediaTypePresentation {
    static func icon(
        _ message:
            Message
    ) -> String {

        switch message.type
            .lowercased() {

        case "image",
             "view_once_image":
            return "photo"

        case "video",
             "video_note",
             "view_once_video":
            return "video"

        case "gif":
            return "sparkles.rectangle.stack"

        case "voice",
             "audio",
             "view_once_audio":
            return "waveform"

        case "document":
            return "doc.fill"

        default:
            return "message"
        }
    }

    static func title(
        _ message:
            Message
    ) -> String {

        switch message.type
            .lowercased() {

        case "image",
             "view_once_image":
            return "Photo"

        case "video":
            return "Video"

        case "video_note":
            return "Video message"

        case "gif":
            return "GIF"

        case "voice":
            return "Voice message"

        case "audio",
             "view_once_audio":
            return "Audio"

        case "document":
            return message.fileName
                ?? "Document"

        default:
            return "Message"
        }
    }
}
