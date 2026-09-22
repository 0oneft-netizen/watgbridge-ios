import Foundation

struct Message: Identifiable, Codable {
    let id: Int64

    let messageID: String
    let chatJID: String
    let senderJID: String

    let text: String
    let type: String

    let fromMe: Bool
    let createdAt: Int64

    let mediaPath: String?
    let mimeType: String?
    let fileName: String?

    enum CodingKeys: String, CodingKey {
        case id

        case messageID = "message_id"
        case chatJID = "chat_jid"
        case senderJID = "sender_jid"

        case text
        case type

        case fromMe = "from_me"
        case createdAt = "created_at"

        case mediaPath = "media_path"
        case mimeType = "mime_type"
        case fileName = "file_name"
    }
}
