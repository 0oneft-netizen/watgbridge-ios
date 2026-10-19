import Foundation

struct LocalAgentConfig: Codable {
    var enabled = false
    var instructions = ""
    var knowledge = ""
    var examples = ""
    var revision: Int64 = 0
}
struct LocalAgentTurn: Codable {
    let role: String
    let content: String
}
struct LocalAgentTest: Decodable {
    let reply: String
    let seconds: Double
    let contextExcerpt: String
    enum CodingKeys: String, CodingKey { case reply, seconds; case contextExcerpt = "context_excerpt" }
}
struct LocalAgentJob: Decodable, Identifiable {
    let id: Int64
    let accountID: String
    let jid: String
    let inputText: String
    let state: String
    let reply: String
    let lastError: String
    let revision: Int64
    let createdAt: Int64
    var stateLabel: String {
        switch state {
        case "pending": return "ממתין לניסוח"
        case "generating": return "המנוע מנסח"
        case "draft": return "טיוטה לבדיקה"
        case "sending": return "שולח לאחר אישור"
        case "sent": return "נשלח"
        case "failed": return "הפעולה לא הושלמה"
        case "uncertain": return "השליחה לא אושרה — בדוק בצ׳אט"
        case "cancelled": return "בוטל"
        default: return state
        }
    }
    enum CodingKeys: String, CodingKey {
        case id, jid, state, reply, revision
        case accountID = "account_id", inputText = "input_text", lastError = "last_error", createdAt = "created_at"
    }
}
struct LocalAgentVersion: Decodable, Identifiable {
    let id: Int64
    let createdAt: Int64
    let config: LocalAgentConfig
    enum CodingKeys: String, CodingKey { case id, config; case createdAt = "created_at" }
}
struct LocalAgentPausedChat: Decodable, Identifiable {
    let accountID: String
    let jid: String
    var id: String { accountID + "|" + jid }
    enum CodingKeys: String, CodingKey { case accountID = "account_id", jid }
}
struct LocalAgentOK: Decodable { let ok: Bool }
@MainActor enum LocalAgentAPI {
    static func request<T: Decodable>(_ suffix: String, workspace: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard workspace != "signed-out", UserWorkspace.id == workspace else { throw CancellationError() }
        let url = UserWorkspace.baseURL.appendingPathComponent("features/local-agent-" + suffix)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 155)
        request.httpMethod = method; request.httpBody = body
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()
        guard UserWorkspace.id == workspace else { throw CancellationError() }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "LocalAgent", code: (response as? HTTPURLResponse)?.statusCode ?? 0,
                          userInfo: [NSLocalizedDescriptionKey: String(data: data.prefix(600), encoding: .utf8) ?? "הפעולה לא הושלמה"])
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    static func json(_ value: [String: Any]) throws -> Data { try JSONSerialization.data(withJSONObject: value) }
}
