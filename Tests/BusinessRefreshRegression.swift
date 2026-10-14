import Foundation

@main
struct BusinessRefreshRegression {
    static func message(_ id: Int64, text: String = "hello", time: Int64 = 10) throws -> Message {
        let object: [String: Any] = ["id": id, "message_id": "wa-\(id)", "chat_jid": "111@s.whatsapp.net",
            "sender_jid": "111@s.whatsapp.net", "text": text, "type": "text", "from_me": false, "created_at": time]
        return try JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: object))
    }
    static func conversation(_ jid: String, unread: Int) throws -> Conversation {
        let object: [String: Any] = ["jid": jid, "name": "Contact", "last_message": "hello", "last_message_at": 10, "unread": unread]
        return try JSONDecoder().decode(Conversation.self, from: JSONSerialization.data(withJSONObject: object))
    }
    @MainActor
    static func main() throws {
        let first = try message(1), second = try message(2), edited = try message(1, text: "edited")
        let reset = MessageSyncBatch(cursor: 10, reset: true, messages: [second, first, first], removed: [])
        let rows = MessageTimelineMerge.apply(reset, to: [try message(99)])
        precondition(rows.map(\.id) == [1, 2], "Reset must replace, deduplicate and order equal timestamps")
        let changes = MessageSyncBatch(cursor: 11, reset: false, messages: [edited], removed: [2])
        precondition(MessageTimelineMerge.apply(changes, to: rows) == [edited], "Edit/delete must merge atomically")
        precondition(MessageTimelineMerge.apply(MessageSyncBatch(cursor: 12, reset: false, messages: [], removed: []), to: rows) == rows)
        precondition(MessageTimelineMerge.apply(MessageSyncBatch(cursor: 13, reset: true, messages: [], removed: []), to: rows).isEmpty)
        let cache = ChatSnapshotStore(limit: 2)
        cache.save(workspace: "owner", account: "a", chat: "111", messages: rows, cursor: 10)
        precondition(cache.snapshot(workspace: "owner", account: "b", chat: "111") == nil, "Accounts must stay isolated")
        precondition(cache.snapshot(workspace: "owner", account: "a", chat: "222") == nil, "Chats must stay isolated")
        precondition(cache.snapshot(workspace: "owner", account: "a", chat: "111")?.cursor == 10)
        cache.save(workspace: "owner", account: "a", chat: "222", messages: rows, cursor: 20)
        _ = cache.snapshot(workspace: "owner", account: "a", chat: "111")
        cache.save(workspace: "owner", account: "a", chat: "333", messages: rows, cursor: 30)
        precondition(cache.snapshot(workspace: "owner", account: "a", chat: "222") == nil, "LRU must bound memory")
        precondition(cache.snapshot(workspace: "other", account: "a", chat: "111") == nil, "Workspace switch must drop old data")
        precondition(cache.snapshot(workspace: "owner", account: "a", chat: "111") == nil, "Old workspace data must not remain")
        cache.save(workspace: "owner", account: "a", chat: "111", messages: Array(repeating: first, count: 2001), cursor: 99)
        precondition(cache.snapshot(workspace: "owner", account: "a", chat: "111") == nil, "Oversized snapshots must not truncate while retaining cursor")
        let group = try conversation("123@g.us", unread: 1), contact = try conversation("123@s.whatsapp.net", unread: 0)
        precondition(BusinessChatFilter.groups.includes(group) && !BusinessChatFilter.groups.includes(contact))
        precondition(BusinessChatFilter.unread.includes(group) && !BusinessChatFilter.unread.includes(contact))
        precondition(BusinessChatFilter.all.includes(group) && BusinessChatFilter.all.includes(contact))
        print("PASS: timeline reset/edit/delete/order; cache workspace/account/chat isolation, LRU and bounds; chat filters")
    }
}
