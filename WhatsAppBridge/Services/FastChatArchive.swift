import Foundation
import CryptoKit

// Serial, protected, account-scoped snapshots. Network sync remains authoritative.
actor FastChatArchive {
    static let shared = FastChatArchive()
    struct Conversations: Codable { let rows: [Conversation]; let etag: String?; let savedAt: Date }
    struct Timeline: Codable { let account: String; let chat: String; let messages: [Message]; let cursor: Int64 }
    private let root: URL
    private var blocked = Set<String>()
    private var lists: [String: Conversations] = [:]
    init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FastChatArchive-v1", isDirectory: true)
    }
    private func hash(_ value: String) -> String { SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined() }
    private func folder(_ scope: String) -> URL { root.appendingPathComponent(hash(scope), isDirectory: true) }
    private func usable(_ scope: String) -> Bool { !scope.isEmpty && !scope.hasSuffix("|signed-out") && !blocked.contains(scope) }
    func activate(scope: String) { blocked.remove(scope) }
    func purge(scope: String) {
        blocked.insert(scope); lists.removeValue(forKey: scope)
        try? FileManager.default.removeItem(at: folder(scope))
    }
    private func write(_ data: Data, to url: URL) throws {
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var dirURL = dir; var values = URLResourceValues(); values.isExcludedFromBackup = true
        try dirURL.setResourceValues(values)
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: [.atomic])
        #endif
    }
    private func data(at url: URL, limit: Int) -> Data? {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size <= limit else { return nil }
        return try? Data(contentsOf: url)
    }
    func conversations(scope: String) -> Conversations? {
        guard usable(scope) else { return nil }
        if let cached = lists[scope] { return cached }
        guard let bytes = data(at: folder(scope).appendingPathComponent("conversations.json"), limit: 8 * 1024 * 1024),
              let saved = try? JSONDecoder().decode(Conversations.self, from: bytes) else { return nil }
        lists[scope] = saved; return saved
    }
    func saveConversations(_ rows: [Conversation], etag: String?, scope: String) {
        guard usable(scope) else { return }
        let value = Conversations(rows: rows, etag: etag, savedAt: Date())
        guard let bytes = try? JSONEncoder().encode(value), bytes.count <= 8 * 1024 * 1024 else { return }
        lists[scope] = value
        try? write(bytes, to: folder(scope).appendingPathComponent("conversations.json"))
    }
    private func timelineURL(scope: String, account: String, chat: String) -> URL {
        folder(scope).appendingPathComponent("chat-" + hash(account + "|" + chat) + ".json")
    }
    func timeline(scope: String, account: String, chat: String) -> Timeline? {
        guard usable(scope) else { return nil }
        guard let bytes = data(at: timelineURL(scope: scope, account: account, chat: chat), limit: 2 * 1024 * 1024),
              let saved = try? JSONDecoder().decode(Timeline.self, from: bytes), saved.account == account, saved.chat == chat,
              saved.messages.count <= 2000,
              saved.messages.allSatisfy({ ($0.accountID ?? "default") == account && $0.chatJID == chat }) else { return nil }
        return saved
    }
    func saveTimeline(scope: String, account: String, chat: String, messages: [Message], cursor: Int64) {
        guard usable(scope) else { return }
        let file = timelineURL(scope: scope, account: account, chat: chat)
        // Never attach a sync cursor to a truncated timeline.
        guard messages.count <= 2000,
              messages.allSatisfy({ ($0.accountID ?? "default") == account && $0.chatJID == chat }),
              let bytes = try? JSONEncoder().encode(Timeline(account: account, chat: chat, messages: messages, cursor: cursor)),
              bytes.count <= 2 * 1024 * 1024 else { try? FileManager.default.removeItem(at: file); return }
        try? write(bytes, to: file)
        trim(scope: scope)
    }
    private func trim(scope: String) {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder(scope), includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])) ?? []
        let chats = files.filter { $0.lastPathComponent.hasPrefix("chat-") }.sorted {
            ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) >
            ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
        }
        var bytes = 0
        for (index, file) in chats.enumerated() {
            bytes += (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            if index >= 40 || bytes > 48 * 1024 * 1024 { try? FileManager.default.removeItem(at: file) }
        }
    }
}

enum FastChatScope {
    static func key(workspace: String) -> String { UserWorkspace.serverURL.absoluteString + "|" + workspace }
}
