import Foundation

enum MediaFilePresentation {
    static func displayName(
        for message: Message
    ) -> String {
        if let fileName = message.fileName,
           !fileName.isEmpty {
            return fileName
        }

        switch message.type.lowercased() {
        case "image":
            return "Photo"

        case "video":
            return "Video"

        case "voice":
            return "Voice message"

        case "audio":
            return "Audio"

        case "document":
            return "Document"

        default:
            return "Media"
        }
    }

    static func fileExtension(
        for message: Message
    ) -> String? {
        if let fileName = message.fileName {
            let value = URL(
                fileURLWithPath: fileName
            ).pathExtension

            if !value.isEmpty {
                return value.uppercased()
            }
        }

        guard let mime = message.mimeType
        else {
            return nil
        }

        return mime
            .split(separator: "/")
            .last
            .map {
                String($0).uppercased()
            }
    }
}
