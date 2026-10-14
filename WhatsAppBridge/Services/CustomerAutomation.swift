import Foundation

struct CustomerAutomationSettings: Codable {
    var staleEnabled = false
    var staleHours = 168
    var aiEnabled = false
    var aiMode = "draft"
    var business = ""
    var tone = "ענה בעברית באופן קצר, ברור ואדיב"
    var model = "gpt-5.4-mini"
    var dailyLimit = 50
    var startHour = 0
    var endHour = 24
    var timezone = "Asia/Jerusalem"
    enum CodingKeys: String, CodingKey {
        case business, tone, model, timezone
        case staleEnabled = "stale_enabled", staleHours = "stale_hours", aiEnabled = "ai_enabled", aiMode = "ai_mode"
        case dailyLimit = "daily_limit", startHour = "start_hour", endHour = "end_hour"
    }
}
struct CustomerAutomationConfiguration: Decodable {
    let settings: CustomerAutomationSettings
    let keyReady: Bool
    enum CodingKeys: String, CodingKey { case settings; case keyReady = "key_ready" }
}
struct AutomationAudienceMember: Decodable, Identifiable {
    let accountID: String
    let jid: String
    let name: String
    let lastAt: Int64
    let preview: String
    var id: String { accountID + "|" + jid }
    var title: String {
        if name != jid && !name.isEmpty { return name }
        return jid.hasSuffix("@s.whatsapp.net") ? String(jid.split(separator: "@").first ?? "") : "איש קשר"
    }
    enum CodingKeys: String, CodingKey { case jid, name, preview; case accountID = "account_id", lastAt = "last_at" }
}
struct AutomationCampaignItem: Decodable, Identifiable {
    let id: Int64
    let accountID: String
    let jid: String
    let name: String
    let state: String
    let lastError: String
    enum CodingKeys: String, CodingKey { case id, jid, name, state; case accountID = "account_id", lastError = "last_error" }
}
struct AutomationCampaignRecord: Decodable, Identifiable {
    let id: Int64
    let source: String
    let text: String
    let hasImage: Bool
    let hasMore: Bool
    let nextItemID: Int64
    let intervalSeconds: Int
    let state: String
    let createdAt: Int64
    let total: Int
    let sent: Int
    let items: [AutomationCampaignItem]
    enum CodingKeys: String, CodingKey { case id, source, text, state, total, sent, items; case hasImage = "has_image", hasMore = "has_more", nextItemID = "next_item_id", intervalSeconds = "interval_seconds", createdAt = "created_at" }
}
struct AutomationAIReply: Decodable, Identifiable {
    let name: String
    let id: Int64
    let accountID: String
    let jid: String
    let inputText: String
    let state: String
    let reply: String
    let lastError: String
    let createdAt: Int64
    enum CodingKeys: String, CodingKey { case id, jid, state, reply, name; case accountID = "account_id", inputText = "input_text", lastError = "last_error", createdAt = "created_at" }
}
struct AutomationPreviewReply: Decodable { let reply: String }

@MainActor
final class CustomerAutomationAPI {
    static let shared = CustomerAutomationAPI()
    func request<T: Decodable>(_ path: String, method: String = "GET", query: [URLQueryItem] = [], body: [String: Any]? = nil) async throws -> T {
        let scope = UserWorkspace.id
        guard scope != "signed-out",
              var parts = URLComponents(url: APIClient.shared.baseURL.appendingPathComponent("features/automation-" + path), resolvingAgainstBaseURL: false) else { throw URLError(.userAuthenticationRequired) }
        parts.queryItems = query.isEmpty ? nil : query
        guard let url = parts.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 45)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body { request.setValue("application/json", forHTTPHeaderField: "Content-Type"); request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()
        guard UserWorkspace.id == scope else { throw CancellationError() }
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data.prefix(500), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "הפעולה לא הושלמה"
            throw NSError(domain: "CustomerAutomation", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    func save(_ settings: CustomerAutomationSettings) async throws -> CustomerAutomationConfiguration {
        let data = try JSONEncoder().encode(settings)
        let body = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return try await request("settings", method: "PUT", body: body)
    }
}
