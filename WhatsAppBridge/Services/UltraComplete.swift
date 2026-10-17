import Foundation
import NaturalLanguage
import Combine

struct UltraChatPreferences: Codable {
    var accountID: String
    var jid: String
    var language = ""
    var manual = false
    var autoTranslate = false
    var muteUntil: Int64 = 0
    var resetLegacyMute = false
    var found = false
    var change = "translation"
    enum CodingKeys: String, CodingKey {
        case accountID = "account_id", jid, language, manual, autoTranslate = "auto_translate", muteUntil = "mute_until", resetLegacyMute = "reset_legacy_mute", found, change
    }
}
struct UltraCustomerMatch: Decodable, Identifiable {
    let accountID: String, jid: String, name: String, phone: String, accountName: String
    let lastAt: Int64
    var id: String { accountID + "|" + jid }
    enum CodingKeys: String, CodingKey { case accountID = "account_id", jid, name, phone, accountName = "account_name", lastAt = "last_at" }
    var conversation: Conversation { .init(accountID: accountID, jid: jid, name: name, displayPhone: phone, lastMessage: "", lastMessageAt: lastAt, unread: 0, pinned: nil, archived: nil, muted: nil) }
}
struct UltraRecipientCheck: Decodable, Identifiable {
    let accountID: String, jid: String, key: String, phone: String, accountName: String, duplicateOf: String
    let accountPhone: String?
    let excluded: Bool, unknownPhone: Bool
    var id: String { key }
    var eligible: Bool { !excluded && duplicateOf.isEmpty }
    enum CodingKeys: String, CodingKey { case accountID = "account_id", jid, key, phone, accountName = "account_name", accountPhone = "account_phone", duplicateOf = "duplicate_of", excluded, unknownPhone = "unknown_phone" }
}
struct UltraSessionAlert: Decodable, Identifiable {
    let id: Int64
    let accountID: String, name: String, reason: String
    let createdAt: Int64
    enum CodingKeys: String, CodingKey { case id, accountID = "account_id", name, reason, createdAt = "created_at" }
}
struct UltraLoginDevice: Decodable, Identifiable {
    let id: String, label: String
    let createdAt: Int64, lastSeen: Int64, expiresAt: Int64
    let current: Bool, revocable: Bool
    enum CodingKeys: String, CodingKey { case id, label, createdAt = "created_at", lastSeen = "last_seen", expiresAt = "expires_at", current, revocable }
}
struct UltraTranscript: Decodable { let text: String, hebrew: String; let translationAvailable: Bool
    enum CodingKeys: String, CodingKey { case text, hebrew, translationAvailable = "translation_available" }
}
struct UltraExclusion: Decodable { let phone: String; let excluded: Bool }
struct UltraCallReady: Decodable { let ready: Bool; let reason: String }

@MainActor enum UltraCompleteAPI {
    static var deviceLabel: String { UserDefaults.standard.string(forKey: "ultra.device.label") ?? "ULTRA-SAP iPhone" }
    static func request<T: Decodable>(_ path: String, workspace: String, method: String = "GET", query: [URLQueryItem] = [], body: [String: Any]? = nil, timeout: Double = 60) async throws -> T {
        guard workspace != "signed-out", workspace == UserWorkspace.id else { throw CancellationError() }
        let base = path.hasPrefix("auth/") ? UserWorkspace.serverURL : UserWorkspace.baseURL
        var parts = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { parts.queryItems = query }
        var request = URLRequest(url: parts.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.httpMethod = method
        if path.hasPrefix("auth/") { request.setValue(deviceLabel, forHTTPHeaderField: "X-Ultra-Device") }
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body); request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation(); guard UserWorkspace.id == workspace else { throw CancellationError() }
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else { throw NSError(domain: "UltraComplete", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: String(data: data.prefix(300), encoding: .utf8) ?? "לא ניתן להשלים את הבקשה"]) }
        return try JSONDecoder().decode(T.self, from: data)
    }
    static func preferences(_ chat: Conversation, workspace: String) async throws -> UltraChatPreferences {
        try await request("features/chat-preferences", workspace: workspace, query: [.init(name: "account_id", value: chat.accountID ?? "default"), .init(name: "jid", value: chat.jid)])
    }
    static func save(_ value: UltraChatPreferences, workspace: String) async throws -> UltraChatPreferences {
        let data = try JSONEncoder().encode(value)
        let body = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        return try await request("features/chat-preferences", workspace: workspace, method: "POST", body: body)
    }
    static func preflight(_ keys: [String], workspace: String) async throws -> [UltraRecipientCheck] {
        try await request("features/broadcast-preflight", workspace: workspace, method: "POST", body: ["selected": keys.sorted()])
    }
    static func checkCall(account: String, workspace: String) async throws {
        let result: UltraCallReady = try await request("features/call-preflight", workspace: workspace, query: [.init(name: "account_id", value: account)], timeout: 8)
        guard result.ready else { throw URLError(.cannotConnectToHost) }
    }
}

@MainActor final class UltraPreferenceStore: ObservableObject {
    static let shared = UltraPreferenceStore()
    @Published private(set) var values: [String: UltraChatPreferences] = [:]
    private var scope = UserWorkspace.id
    func reload() { scope = UserWorkspace.id; values = [:] }
    func language(_ chat: Conversation) -> String {
        values[chat.id]?.language ?? UserWorkspace.defaults.string(forKey: "ultra.language." + chat.id) ?? ""
    }
    func load(_ chat: Conversation) async throws -> UltraChatPreferences {
        if scope != UserWorkspace.id { reload() }
        let user = scope
        var value = try await UltraCompleteAPI.preferences(chat, workspace: user)
        if !value.found {
            value.autoTranslate = UserWorkspace.defaults.bool(forKey: "ultra.translate.auto." + chat.id)
            value.language = UserWorkspace.defaults.string(forKey: "ultra.language." + chat.id) ?? ""
        }
        guard user == UserWorkspace.id else { throw CancellationError() }
        values[chat.id] = value; return value
    }
    func save(_ value: UltraChatPreferences, chat: Conversation) async throws {
        let user = scope; guard user == UserWorkspace.id else { throw CancellationError() }
        let result = try await UltraCompleteAPI.save(value, workspace: user)
        guard user == UserWorkspace.id else { throw CancellationError() }
        values[chat.id] = result
        UserWorkspace.defaults.set(result.language, forKey: "ultra.language." + chat.id)
        UserWorkspace.defaults.set(result.manual, forKey: "ultra.language.manual." + chat.id)
        UserWorkspace.defaults.set(result.autoTranslate, forKey: "ultra.translate.auto." + chat.id)
    }
    func observe(_ messages: [Message], chat: Conversation) async {
        let user = scope
        guard user == UserWorkspace.id else { return }
        do {
            var value: UltraChatPreferences
            if let cached = values[chat.id] { value = cached } else { value = try await load(chat) }
            guard !value.manual, let latest = messages.last(where: { !$0.fromMe && !$0.text.isEmpty && $0.deletedRemote != true }), let code = UltraLanguagePolicy.detected(latest.text), code != value.language else { return }
            value.language = code; try await save(value, chat: chat)
        } catch { }
    }
}

enum UltraSettingsBackupPolicy {
    static let fixed = ["notificationsEnabled","notificationPreview","notificationSound","badgeEnabled","hapticsEnabled","mediaAutoDownload","saveReceivedMedia","ultra.signature","ultra.voice.preset.v1"]
    static func allows(_ key: String) -> Bool { key.count < 512 && (fixed.contains(key) || key.hasPrefix("ultra.language.") || key.hasPrefix("ultra.translate.auto.")) }
    static func snapshot(_ defaults: UserDefaults) -> [String: Any] {
        defaults.dictionaryRepresentation().filter { allows($0.key) && ($0.value is String || $0.value is NSNumber) }
    }
}
