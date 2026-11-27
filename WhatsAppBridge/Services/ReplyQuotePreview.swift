import Foundation

struct ReplyQuotePreview: Codable, Equatable {
    let accountID: String
    let chatJID: String
    let replyMessageID: String
    let messageID: String
    let text: String
    let type: String
    let source: String
    let available: Bool
    let navigable: Bool
    let fromMe: Bool
    enum CodingKeys: String, CodingKey {
        case text, type, source, available, navigable
        case accountID = "account_id", chatJID = "chat_jid"
        case replyMessageID = "reply_message_id", messageID = "message_id", fromMe = "from_me"
    }
    var label: String {
        guard available else { return "ההודעה המקורית אינה זמינה" }
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return text }
        switch type {
        case "image": return "תמונה"
        case "video", "gif": return "סרטון"
        case "video_note", "ptv": return "הודעת וידאו"
        case "audio", "voice": return "הודעה קולית"
        case "document": return "מסמך"
        case "sticker": return "מדבקה"
        default: return "הודעה"
        }
    }
    static func local(reply: Message, messages: [Message]) -> ReplyQuotePreview? {
        guard let id = reply.replyToID, !id.isEmpty,
              let original = messages.first(where: {
                  $0.messageID == id && ($0.accountID ?? "default") == (reply.accountID ?? "default") && $0.chatJID == reply.chatJID
              }) else { return nil }
        let visible = original.deletedLocal != true && original.deletedRemote != true && !original.type.hasPrefix("view_once")
        return ReplyQuotePreview(accountID: reply.accountID ?? "default", chatJID: reply.chatJID,
            replyMessageID: reply.messageID, messageID: id, text: visible ? String(original.text.prefix(2000)) : "", type: original.type,
            source: "history", available: visible, navigable: visible, fromMe: original.fromMe)
    }
}
struct ReplyQuoteNavigation {
    let workspace: String
    let account: String
    let chat: String
    let messageID: String
}
extension Notification.Name { static let replyQuoteNavigation = Notification.Name("ultra.reply.quote.navigation") }
