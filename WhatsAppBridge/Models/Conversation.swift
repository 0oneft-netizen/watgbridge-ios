import Foundation

struct Conversation: Identifiable, Codable {
    var id: String { jid }

    let jid: String
    let name: String
    let lastMessage: String
    let lastMessageAt: Int64
    let unread: Int

    enum CodingKeys: String, CodingKey {
        case jid
        case name
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case unread
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty && trimmed != jid {
            return trimmed
        }

        return cleanNumber
    }

    var cleanNumber: String {
        jid
            .replacingOccurrences(of: "@s.whatsapp.net", with: "")
            .replacingOccurrences(of: "@lid", with: "")
            .replacingOccurrences(of: "@g.us", with: "")
    }

    var previewText: String {
        let trimmed = lastMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No messages yet" : trimmed
    }

    var initials: String {
        let parts = displayName
            .split(separator: " ")
            .prefix(2)

        let value = parts.compactMap { $0.first }.map(String.init).joined()

        return value.isEmpty ? "?" : value.uppercased()
    }
}
