import Foundation

// A deliberately isolated test workspace; no production host, credentials or standard defaults.
enum UserWorkspace {
    static var id = "alpha"
    static let namespace = "ultra-suite-contracts-" + UUID().uuidString
    static var defaults: UserDefaults { UserDefaults(suiteName: namespace + "." + id)! }
    static var baseURL: URL { URL(string: "https://unit.invalid/u/" + id)! }
}
@main struct UltraSuiteContracts {
    @MainActor static func main() throws {
        func message(_ account: String, _ id: Int) throws -> Message {
            let json: [String: Any] = ["id": id, "account_id": account, "message_id": "same-wa", "chat_jid": "1@s.whatsapp.net", "sender_jid": "1@s.whatsapp.net", "text": "hello", "type": "text", "from_me": false, "created_at": 100]
            return try JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: json))
        }
        let a = try message("a",1), b = try message("b",2)
        precondition(UltraChatStore.key(a) != UltraChatStore.key(b))
        let store = UltraChatStore.shared
        store.togglePin(a); store.togglePin(b); precondition(store.pins.count == 2)
        UserWorkspace.id = "beta"; store.reload(); precondition(store.pins.isEmpty && store.recents.isEmpty && store.translations.isEmpty)
        UserWorkspace.id = "alpha"; store.reload(); precondition(store.pins.count == 2)
        store.togglePin(a); precondition(!store.pinned(a) && store.pinned(b))
        for index in 0..<25 {
            let json: [String: Any] = ["account_id":"a", "jid":"\(index)@s.whatsapp.net", "name":"Contact", "last_message":"test", "last_message_at":100, "unread":0]
            let chat = try JSONDecoder().decode(Conversation.self, from: JSONSerialization.data(withJSONObject: json))
            store.visit(chat)
        }
        precondition(store.recents.count == 20 && store.recents.first?.conversation.jid == "24@s.whatsapp.net")
        let entry = UltraQueuedSend(id: UUID(), account: "a", chat: "1@s.whatsapp.net", summary: "hello", route: "/send", contentType: "application/json", created: Date())
        let restored = try JSONDecoder().decode(UltraQueuedSend.self, from: JSONEncoder().encode(entry))
        precondition(restored.id == entry.id && restored.route == entry.route && restored.state == "queued")
        let batch = try JSONDecoder().decode(UltraMediaBatch.self, from: Data("{\"messages\":[],\"has_more\":true}".utf8))
        precondition(batch.hasMore && batch.messages.isEmpty)
        let result = try JSONDecoder().decode(UltraTranslationResult.self, from: Data("{\"items\":[{\"key\":\"a\",\"text\":\"שלום\"}]}".utf8))
        precondition(result.items.first?.text == "שלום")
        for id in ["alpha","beta"] { UserDefaults.standard.removePersistentDomain(forName: UserWorkspace.namespace + "." + id) }
        print("PASS: account and user isolation, persistent private pins, 20 recent chats, receipt UUID persistence, media and translation contracts")
    }
}
