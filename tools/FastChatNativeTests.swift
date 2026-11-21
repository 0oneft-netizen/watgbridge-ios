import Foundation

enum UserWorkspace { static let serverURL = URL(string: "https://unit.example")! }

@main struct FastChatNativeTests {
    static func check(_ value: Bool, _ label: String) throws {
        if !value { throw NSError(domain: "FastChatTests", code: 1, userInfo: [NSLocalizedDescriptionKey: label]) }
        print("PASS:", label)
    }
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = FastChatArchive(root: root)
        let a = "https://unit.example|owner", b = "https://unit.example|other"
        let c = Conversation(accountID: "acc-a", jid: "972501234567@s.whatsapp.net", name: "Example", displayPhone: "+972501234567", lastMessage: "hello", lastMessageAt: 100, unread: 1, pinned: false, archived: false, muted: false)
        await store.saveConversations([c], etag: "quoted-tag", scope: a)
        let restarted = FastChatArchive(root: root)
        let restored = await restarted.conversations(scope: a)
        try check(restored?.rows == [c] && restored?.etag == "quoted-tag", "conversation list survives restart with ETag")
        let other = await restarted.conversations(scope: b)
        try check(other == nil, "workspace isolation")
        let msg = try JSONDecoder().decode(Message.self, from: Data(#"{"id":1,"message_id":"m1","account_id":"acc-a","chat_jid":"972501234567@s.whatsapp.net","sender_jid":"","text":"hello","type":"text","from_me":false,"created_at":100}"#.utf8))
        await store.saveTimeline(scope: a, account: "acc-a", chat: c.jid, messages: [msg], cursor: 20)
        let timeline = await restarted.timeline(scope: a, account: "acc-a", chat: c.jid)
        try check(timeline?.messages == [msg] && timeline?.cursor == 20, "complete timeline and cursor survive restart")
        let wrong = await store.timeline(scope: a, account: "acc-b", chat: c.jid)
        try check(wrong == nil, "same phone in different account stays isolated")
        let removed = MessageTimelineMerge.apply(MessageSyncBatch(cursor: 21, reset: false, messages: [], removed: [1]), to: timeline!.messages)
        await store.saveTimeline(scope: a, account: "acc-a", chat: c.jid, messages: removed, cursor: 21)
        let deleted = await restarted.timeline(scope: a, account: "acc-a", chat: c.jid)
        try check(deleted?.messages.isEmpty == true && deleted?.cursor == 21, "remote/local deletion delta stays removed in persistent snapshot")
        await store.saveTimeline(scope: a, account: "acc-a", chat: c.jid, messages: Array(repeating: msg, count: 2001), cursor: 22)
        let truncated = await store.timeline(scope: a, account: "acc-a", chat: c.jid)
        try check(truncated == nil, "oversized timeline never keeps a misleading cursor")
        await store.purge(scope: a)
        await store.saveConversations([c], etag: "late-write", scope: a)
        let afterLogout = await store.conversations(scope: a)
        let cleanDisk = await FastChatArchive(root: root).conversations(scope: a)
        try check(afterLogout == nil && cleanDisk == nil, "logout purges disk and rejects late writes")
        await store.activate(scope: a)
        await store.saveConversations([c], etag: "new-login", scope: a)
        let newLogin = await store.conversations(scope: a)
        try check(newLogin?.rows == [c], "new authenticated login can cache again")
        for (input, expected) in [("0501234567","972501234567"),("+972501234567","972501234567"),("00972501234567","972501234567"),("+1 (415) 555-2671","14155552671"),("03-1234567","97231234567")] {
            try check(NewChatPhone.digits(input) == expected, "phone normalization " + input)
        }
        for input in ["", "123", "123456789@lid", "../../other", "+123+456789", "050123", "letters+14155552671"] {
            try check(NewChatPhone.digits(input) == nil, "invalid recipient rejected " + input)
        }
    }
}
