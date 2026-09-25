import Foundation

struct UnifiedReplyTarget: Identifiable, Equatable {
    let id: String
    let accountID: String
    let chatJID: String
    let messageID: String
    let sender: String
    let preview: String

    init(
        message: Message,
        sender: String
    ) {
        id =
            "\(message.accountID)|\(message.messageID)"

        accountID = message.accountID ?? "default"
        chatJID = message.chatJID
        messageID = message.messageID
        self.sender = sender

        if !message.text.isEmpty {
            preview = message.text
        } else {
            switch message.type {
            case "image":
                preview = "Photo"
            case "video":
                preview = "Video"
            case "video_note":
                preview = "Video message"
            case "voice":
                preview = "Voice message"
            case "audio":
                preview = "Audio"
            case "document":
                preview =
                    message.fileName ?? "Document"
            default:
                preview = "Message"
            }
        }
    }
}
