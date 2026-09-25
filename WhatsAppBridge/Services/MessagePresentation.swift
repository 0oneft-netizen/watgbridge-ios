import Foundation

enum MessagePresentation {
    static func preview(
        for message: Message
    ) -> String {
        if message.deletedRemote == true {
            return "Message deleted"
        }

        if !message.text.isEmpty {
            return message.text
        }

        switch message.type {
        case "image":
            return "📷 Photo"

        case "video":
            return "🎥 Video"

        case "video_note":
            return "◉ Video message"

        case "voice":
            return "🎤 Voice message"

        case "audio":
            return "🎵 Audio"

        case "document":
            return "📄 \(message.fileName ?? "Document")"

        case "gif":
            return "GIF"

        case "view_once_image":
            return "① Photo"

        case "view_once_video":
            return "① Video"

        case "view_once_audio":
            return "① Voice message"

        default:
            return "Message"
        }
    }

    static func timestamp(
        _ value: Int64
    ) -> String {
        let seconds: TimeInterval

        if value > 10_000_000_000 {
            seconds =
                TimeInterval(value)
                / 1000
        } else {
            seconds =
                TimeInterval(value)
        }

        return Date(
            timeIntervalSince1970:
                seconds
        )
        .formatted(
            date: .omitted,
            time: .shortened
        )
    }
}
