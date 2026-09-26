import Foundation

enum MessagePresentation {
    static func fallbackText(
        for message: Message
    ) -> String {
        if !message.text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            return message.text
        }

        switch message.type.lowercased() {
        case "image":
            return "Photo"

        case "video":
            return "Video"

        case "gif":
            return "GIF"

        case "voice":
            return "Voice message"

        case "audio":
            return "Audio"

        case "video_note", "ptv":
            return "Video message"

        case "document":
            return message.fileName
                ?? "Document"

        case "sticker":
            return "Sticker"

        case "contact":
            return "Contact"

        case "location":
            return "Location"

        case "view_once",
             "view_once_image",
             "view_once_video":
            return "View once"

        default:
            return "Message"
        }
    }

    static func systemImage(
        for message: Message
    ) -> String? {
        switch message.type.lowercased() {
        case "image":
            return "photo"

        case "video":
            return "video"

        case "gif":
            return "photo.stack"

        case "voice":
            return "waveform"

        case "audio":
            return "music.note"

        case "video_note", "ptv":
            return "video.circle"

        case "document":
            return "doc"

        case "contact":
            return "person.crop.circle"

        case "location":
            return "location"

        case "view_once",
             "view_once_image",
             "view_once_video":
            return "viewfinder"

        default:
            return nil
        }
    }
}
