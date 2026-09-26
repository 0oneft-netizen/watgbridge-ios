import Foundation

enum MessageTypePresentation {
    static func label(
        for message: Message
    ) -> String {
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
            return message.fileName ?? "Document"
        case "sticker":
            return "Sticker"
        case "contact":
            return "Contact"
        case "location":
            return "Location"
        default:
            return message.text
        }
    }

    static func icon(
        for message: Message
    ) -> String {
        switch message.type.lowercased() {
        case "image":
            return "photo"
        case "video":
            return "video"
        case "gif":
            return "photo.on.rectangle"
        case "voice", "audio":
            return "waveform"
        case "video_note", "ptv":
            return "video.circle"
        case "document":
            return "doc"
        case "sticker":
            return "face.smiling"
        case "contact":
            return "person.crop.circle"
        case "location":
            return "location"
        default:
            return "message"
        }
    }
}
