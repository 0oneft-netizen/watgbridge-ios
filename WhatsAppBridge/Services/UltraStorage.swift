import Foundation

struct UltraStorageItem: Decodable {
    let id: Int64
    let accountID: String, chatJID: String, messageID: String, fileName: String, mimeType: String, type: String
    enum CodingKeys: String, CodingKey { case id, accountID = "account_id", chatJID = "chat_jid", messageID = "message_id", fileName = "file_name", mimeType = "mime_type", type }
}
struct UltraStorageInventory: Decodable {
    let items: [UltraStorageItem]
    let hasMore: Bool
    let after: Int64
    enum CodingKeys: String, CodingKey { case items, hasMore = "has_more", after }
}
struct UltraCacheEntry: Codable, Identifiable {
    var id: String { file }
    let workspace: String, account: String, chat: String, message: String, file: String, name: String
    var kept: Bool
    var key: String { account + "|" + message }
}
struct UltraCacheFile: Identifiable {
    let entry: UltraCacheEntry
    let bytes: Int64
    let protected: Bool
    var id: String { entry.id }
}
struct UltraCacheChat: Identifiable {
    let account: String, chat: String
    let files: [UltraCacheFile]
    var id: String { account + "|" + chat }
    var bytes: Int64 { files.reduce(0) { $0 + $1.bytes } }
    var removableBytes: Int64 { files.filter { !$0.protected }.reduce(0) { $0 + $1.bytes } }
}
