import Foundation
import CryptoKit
import Combine

struct UltraMediaBatch: Decodable { let messages: [Message]; let hasMore: Bool
    enum CodingKeys: String, CodingKey { case messages; case hasMore = "has_more" }
}
struct UltraTranslation: Codable { let key: String; let text: String }
struct UltraTranslationResult: Decodable { let items: [UltraTranslation] }
enum UltraSuiteAPI {
    static let languages = [("he", "עברית"), ("en", "English"), ("ar", "العربية"), ("ru", "Русский"), ("fr", "Français"), ("es", "Español"), ("de", "Deutsch"), ("pt", "Português"), ("uk", "Українська")]
    static func request<T: Decodable>(_ path: String, query: [URLQueryItem] = [], body: Data? = nil) async throws -> T {
        let scope = UserWorkspace.id
        guard scope != "signed-out" else { throw URLError(.userAuthenticationRequired) }
        var components = URLComponents(url: UserWorkspace.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!); request.timeoutInterval = 45
        if let body { request.httpMethod = "POST"; request.httpBody = body; request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()
        guard UserWorkspace.id == scope else { throw CancellationError() }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let text = String(data: data.prefix(400), encoding: .utf8) ?? "לא ניתן להשלים את הבקשה"
            throw NSError(domain: "UltraSuite", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: text])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    static func media(account: String? = nil, chat: String? = nil, before: Int64? = nil, after: Int64? = nil) async throws -> UltraMediaBatch {
        var q: [URLQueryItem] = []
        if let account { q.append(.init(name: "account_id", value: account)) }
        if let chat { q.append(.init(name: "chat_jid", value: chat)) }
        if let before { q.append(.init(name: "before", value: String(before))) }
        if let after { q.append(.init(name: "after", value: String(after))) }
        return try await request("features/ultra-media", query: q)
    }
    static func translate(_ items: [UltraTranslation], target: String) async throws -> [UltraTranslation] {
        let data = try JSONSerialization.data(withJSONObject: ["target": target, "items": items.map { ["key": $0.key, "text": $0.text] }])
        let result: UltraTranslationResult = try await request("features/ultra-translate", body: data)
        return result.items
    }
}

struct UltraRecentChat: Codable, Identifiable {
    let conversation: Conversation
    let openedAt: Date
    var id: String { conversation.id }
}
@MainActor final class UltraChatStore: ObservableObject {
    static let shared = UltraChatStore()
    @Published private(set) var pins: [Message] = []
    @Published private(set) var recents: [UltraRecentChat] = []
    @Published private(set) var translations: [String: String] = [:]
    private var scope = UserWorkspace.id
    private init() { reload() }
    nonisolated static func key(_ message: Message) -> String { "\(message.accountID ?? "default")|\(message.chatJID)|\(message.messageID)" }
    func reload() {
        scope = UserWorkspace.id; translations = [:]
        pins = decode([Message].self, "ultra.pins.v1") ?? []
        recents = decode([UltraRecentChat].self, "ultra.recents.v1") ?? []
    }
    private func decode<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = UserWorkspace.defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    private func save<T: Encodable>(_ value: T, _ key: String) { if scope == UserWorkspace.id, let data = try? JSONEncoder().encode(value) { UserWorkspace.defaults.set(data, forKey: key) } }
    func visit(_ conversation: Conversation) {
        if scope != UserWorkspace.id { reload() }
        recents.removeAll { $0.id == conversation.id }; recents.insert(.init(conversation: conversation, openedAt: Date()), at: 0)
        recents = Array(recents.prefix(20)); save(recents, "ultra.recents.v1")
    }
    func pinned(_ message: Message) -> Bool { pins.contains { Self.key($0) == Self.key(message) } }
    func togglePin(_ message: Message) {
        guard scope == UserWorkspace.id, !MessageMediaPolicy.isViewOnce(message), message.deletedRemote != true, message.deletedLocal != true else { return }
        if pinned(message) { pins.removeAll { Self.key($0) == Self.key(message) } } else { pins.append(message); pins = Array(pins.suffix(100)) }
        save(pins, "ultra.pins.v1")
    }
    func translation(_ message: Message, target: String = "he") -> String? { if UltraLanguagePolicy.skipHebrew(message.text, target: target) { return nil }; return translations[target + "|" + Self.key(message)] }
    func translate(_ messages: [Message], target: String) async throws {
        let user = UserWorkspace.id
        for message in messages where UltraLanguagePolicy.skipHebrew(message.text, target: target) { translations[target + "|" + Self.key(message)] = message.text }
        let items = messages.filter { !$0.text.isEmpty && $0.deletedRemote != true && !MessageMediaPolicy.isViewOnce($0) && !UltraLanguagePolicy.skipHebrew($0.text, target: target) }.prefix(20)
        guard !items.isEmpty else { return }
        let keyMap = Dictionary(uniqueKeysWithValues: items.map { message -> (String, String) in
            let internalKey = Self.key(message)
            return (SHA256.hash(data: Data(internalKey.utf8)).map { String(format: "%02x", $0) }.joined(), internalKey)
        })
        var batch: [UltraTranslation] = [], bytes = 0
        func consume(_ batch: [UltraTranslation]) async throws {
            let result = try await UltraSuiteAPI.translate(batch, target: target)
            guard user == UserWorkspace.id else { throw CancellationError() }
            if translations.count > 1000 { translations.removeAll() }
            for item in result { if let internalKey = keyMap[item.key] { translations[target + "|" + internalKey] = item.text } }
        }
        for message in items {
            let count = message.text.utf8.count
            guard count <= 12000 else { throw NSError(domain: "UltraTranslate", code: 413, userInfo: [NSLocalizedDescriptionKey: "הודעה ארוכה מדי לתרגום. בחר טקסט קצר יותר."]) }
            if bytes + count > 48000 { try await consume(batch); batch = []; bytes = 0 }
            let opaque = SHA256.hash(data: Data(Self.key(message).utf8)).map { String(format: "%02x", $0) }.joined()
            batch.append(.init(key: opaque, text: message.text)); bytes += count
        }
        if !batch.isEmpty { try await consume(batch) }

    }
}

struct UltraQueuedSend: Codable, Identifiable {
    let id: UUID
    let account: String
    let chat: String
    let summary: String
    let route: String
    let contentType: String
    let created: Date
    var state = "queued"
    var attempts = 0
    var error = ""
}
@MainActor final class UltraSendQueue: ObservableObject {
    static let shared = UltraSendQueue()
    @Published private(set) var items: [UltraQueuedSend] = []
    private var scope = ""
    private var work: Task<Void, Never>?
    private var generation = UUID()
    private init() { reload() }
    private func directory(_ scope: String) throws -> URL {
        let hash = SHA256.hash(data: Data(scope.utf8)).map { String(format: "%02x", $0) }.joined()
        let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("UltraSendQueue").appendingPathComponent(hash)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        var resource = URLResourceValues(); resource.isExcludedFromBackup = true; var url = root; try url.setResourceValues(resource)
        return root
    }
    private func persist() throws {
        let data = try JSONEncoder().encode(items)
        try UltraProtectedFile.write(data, to: directory(scope).appendingPathComponent("index.json"))
    }
    func reload() {
        work?.cancel(); work = nil; generation = UUID(); scope = UserWorkspace.id; items = []
        guard scope != "signed-out", let folder = try? directory(scope), let data = try? Data(contentsOf: folder.appendingPathComponent("index.json")), let stored = try? JSONDecoder().decode([UltraQueuedSend].self, from: data) else { return }
        items = stored.map { item in var value = item; if value.state == "sending" { value.state = "queued" }; return value }
    }
    func submit(_ request: URLRequest, route: String, account: String, chat: String, summary: String) async throws {
        if scope != UserWorkspace.id { reload() }
        guard scope != "signed-out", request.url?.absoluteString.hasPrefix(UserWorkspace.baseURL.absoluteString + "/") == true, let body = request.httpBody, !body.isEmpty, body.count <= 105 * 1024 * 1024 else { throw URLError(.dataLengthExceedsMaximum) }
        guard items.filter({ $0.state != "sent" && $0.state != "cancelled" }).count < 100 else { throw NSError(domain: "UltraQueue", code: 1, userInfo: [NSLocalizedDescriptionKey: "תור השליחה מלא. בדוק את השליחות הממתינות."]) }
        let user = scope, token = generation, folder = try directory(user), id = UUID()
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        let bytes = files.reduce(0) { $0 + ((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
        guard bytes + body.count < 350 * 1024 * 1024 else { throw URLError(.dataLengthExceedsMaximum) }
        let destination = folder.appendingPathComponent(id.uuidString + ".body")
        try await Task.detached(priority: .userInitiated) { try UltraProtectedFile.write(body, to: destination) }.value
        guard user == UserWorkspace.id, token == generation else { try? FileManager.default.removeItem(at: destination); throw CancellationError() }
        let item = UltraQueuedSend(id: id, account: account, chat: chat, summary: String(summary.prefix(1000)), route: route, contentType: request.value(forHTTPHeaderField: "Content-Type") ?? "application/json", created: Date())
        let sent = items.filter { $0.state == "sent" }.suffix(200).map(\.id)
        items.removeAll { $0.state == "sent" && !sent.contains($0.id) }
        items.append(item)
        do { try persist() } catch { items.removeAll { $0.id == id }; try? FileManager.default.removeItem(at: destination); throw error }
        kick()
    }
    func kick() {
        if scope != UserWorkspace.id { reload() }
        guard work == nil, scope != "signed-out" else { return }
        let user = scope, token = generation
        work = Task {
            defer { if token == generation { work = nil } }
            while let id = items.first(where: { $0.state == "queued" && $0.attempts < 8 })?.id {
                guard token == generation, user == UserWorkspace.id, !Task.isCancelled else { return }
                guard let index = items.firstIndex(where: { $0.id == id }) else { continue }
                items[index].state = "sending"; items[index].attempts += 1
                do { try persist() } catch { items[index].state = "failed"; items[index].error = "לא ניתן לשמור את מצב השליחה"; return }
                let item = items[index]
                do {
                    var request = URLRequest(url: UserWorkspace.baseURL.appendingPathComponent("features/ultra-send")); request.httpMethod = "POST"; request.timeoutInterval = 95
                    request.setValue(id.uuidString, forHTTPHeaderField: "Idempotency-Key"); request.setValue(item.route, forHTTPHeaderField: "X-Ultra-Route"); request.setValue(item.contentType, forHTTPHeaderField: "Content-Type")
                    let file = try directory(user).appendingPathComponent(id.uuidString + ".body")
                    let (_, response) = try await URLSession.shared.upload(for: request, fromFile: file)
                    guard token == generation, user == UserWorkspace.id, !Task.isCancelled else { return }
                    guard let current = items.firstIndex(where: { $0.id == id }), let http = response as? HTTPURLResponse else { continue }
                    if (200...299).contains(http.statusCode) {
                        items[current].state = "sent"; items[current].error = ""; try? FileManager.default.removeItem(at: file)
                        NotificationCenter.default.post(name: Notification.Name("bridgeRealtimeUpdate"), object: nil)
                    } else if http.value(forHTTPHeaderField: "X-Ultra-Send-State") == "not-attempted" {
                        items[current].state = "failed"; items[current].error = "ההקלטה לא נשלחה: ממיר הקול בשרת אינו זמין. אחרי תיקון השרת אפשר לנסות שוב."
                    } else if http.statusCode == 409 {
                        items[current].state = "uncertain"; items[current].error = "מצב השליחה אינו ודאי. בדוק בצ׳אט; עותק נוסף לא יישלח אוטומטית."
                    } else if http.statusCode == 401 || http.statusCode == 403 {
                        items[current].state = "failed"; items[current].error = "נדרשת התחברות או הרשאת חשבון"
                    } else {
                        items[current].state = "queued"; items[current].error = "השרת אינו זמין כרגע (\(http.statusCode))"
                    }
                } catch {
                    guard token == generation, user == UserWorkspace.id else { return }
                    if let current = items.firstIndex(where: { $0.id == id }) { items[current].state = "queued"; items[current].error = "ממתין לחיבור. הניסיון הבא ישתמש באותו מזהה שליחה." }
                }
                if let current = items.firstIndex(where: { $0.id == id }), items[current].state == "queued", items[current].attempts >= 8 {
                    items[current].state = "failed"; items[current].error = "לא הושלם לאחר 8 ניסיונות. אפשר לנסות שוב באותו מזהה."
                }
                try? persist()
                if let current = items.first(where: { $0.id == id }), current.state == "queued" { return }
            }
        }
    }
    func retry(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }), items[i].state != "uncertain", items[i].state != "sent", items[i].state != "sending" else { return }
        items[i].state = "queued"; items[i].attempts = 0; try? persist(); kick()
    }
    func remove(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }), items[i].state != "sending" else { return }
        try? FileManager.default.removeItem(at: directory(scope).appendingPathComponent(id.uuidString + ".body"))
        items.remove(at: i); try? persist()
    }
    func reconcile(_ id: UUID) async {
        let user = scope
        struct Status: Decodable { let state: String }
        do {
            let status: Status = try await UltraSuiteAPI.request("features/ultra-send-status", query: [.init(name: "key", value: id.uuidString)])
            guard user == scope, user == UserWorkspace.id, let index = items.firstIndex(where: { $0.id == id }) else { return }
            if status.state == "sent" { items[index].state = "sent"; items[index].error = ""; try? FileManager.default.removeItem(at: directory(scope).appendingPathComponent(id.uuidString + ".body")) }
            try? persist()
        } catch { }
    }
}

private enum UltraProtectedFile {
    static func write(_ data: Data, to url: URL) throws {
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }
}
