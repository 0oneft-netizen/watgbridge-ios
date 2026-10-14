import Foundation

@MainActor
final class ChatSnapshotStore {
    static let shared = ChatSnapshotStore()
    struct Snapshot { let messages: [Message]; let cursor: Int64 }
    private struct Key: Hashable { let account: String; let chat: String }
    private var workspace: String?
    private var values: [Key: Snapshot] = [:]
    private var order: [Key] = []
    private let limit: Int
    init(limit: Int = 12) { self.limit = max(1, limit) }
    func clear() { values.removeAll(); order.removeAll(); workspace = nil }
    private func select(_ scope: String) {
        if workspace != scope { clear(); workspace = scope }
    }
    func snapshot(workspace: String, account: String, chat: String) -> Snapshot? {
        select(workspace)
        let key = Key(account: account, chat: chat)
        guard let value = values[key] else { return nil }
        order.removeAll { $0 == key }; order.append(key)
        return value
    }
    func save(workspace: String, account: String, chat: String, messages: [Message], cursor: Int64) {
        select(workspace)
        let key = Key(account: account, chat: chat)
        // Keep the complete timeline or no snapshot: a truncated timeline must not retain its cursor.
        guard messages.count <= 2000 else { values.removeValue(forKey: key); order.removeAll { $0 == key }; return }
        values[key] = Snapshot(messages: messages, cursor: cursor)
        order.removeAll { $0 == key }; order.append(key)
        while order.count > limit { values.removeValue(forKey: order.removeFirst()) }
    }
}
