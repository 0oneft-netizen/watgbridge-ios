import Foundation

struct CustomerSearchHit: Codable, Identifiable {
    let message: Message
    let name: String
    let phone: String
    let accountName: String
    var id: Int64 { message.id }
    enum CodingKeys: String, CodingKey { case message, name, phone; case accountName = "account_name" }
    var conversation: Conversation {
        Conversation(accountID: message.accountID, jid: message.chatJID, name: name,
                     displayPhone: phone.isEmpty ? nil : phone, lastMessage: message.text,
                     lastMessageAt: message.createdAt, unread: 0, pinned: false, archived: false, muted: false)
    }
}
struct SessionNetworkSettings: Codable {
    let accountID: String
    let enabled: Bool
    let address: String
    enum CodingKeys: String, CodingKey { case enabled, address; case accountID = "account_id" }
}
struct CustomerContactState: Codable {
    let blocked: Bool
    let excludeBroadcast: Bool
    enum CodingKeys: String, CodingKey { case blocked; case excludeBroadcast = "exclude_broadcast" }
}
struct CustomerBroadcastItem: Codable, Identifiable {
    let id: Int64
    let customerID: Int64
    let accountID: String
    let jid: String
    let name: String
    let text: String
    let state: String
    let messageID: String
    let lastError: String
    enum CodingKeys: String, CodingKey {
        case id, jid, name, text, state
        case customerID = "customer_id", accountID = "account_id", messageID = "message_id", lastError = "last_error"
    }
}
struct CustomerBroadcast: Codable, Identifiable {
    let id: Int64
    let groupID: Int64
    let title: String
    let text: String
    let intervalSeconds: Int
    let state: String
    let nextAt: Int64
    let createdAt: Int64
    let items: [CustomerBroadcastItem]
    enum CodingKeys: String, CodingKey {
        case id, title, text, state, items
        case groupID = "group_id", intervalSeconds = "interval_seconds", nextAt = "next_at", createdAt = "created_at"
    }
}
struct FeatureAccepted: Codable { let ok: Bool }
struct FeatureCreated: Codable { let id: Int64 }
final class CustomerFeaturesAPI {
    static let shared = CustomerFeaturesAPI()
    func request<T: Decodable>(_ path: String, method: String = "GET", query: [URLQueryItem] = [], body: [String: Any]? = nil) async throws -> T {
        guard var parts = URLComponents(url: APIClient.shared.baseURL.appendingPathComponent("features/" + path), resolvingAgainstBaseURL: false) else { throw URLError(.badURL) }
        parts.queryItems = query.isEmpty ? nil : query
        guard let url = parts.url else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = method; req.timeoutInterval = 60
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body); req.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CRMError(message: String(data: data, encoding: .utf8) ?? "הפעולה לא הושלמה")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    func search(_ query: String, before: Int64? = nil) async throws -> [CustomerSearchHit] {
        var items = [URLQueryItem(name: "q", value: query)]
        if let before { items.append(URLQueryItem(name: "before", value: String(before))) }
        return try await request("search", query: items)
    }
    func context(_ conversation: Conversation, messageID: String) async throws -> [Message] {
        try await request("message-context", query: [URLQueryItem(name: "account_id", value: conversation.accountID ?? "default"), URLQueryItem(name: "chat_jid", value: conversation.jid), URLQueryItem(name: "message_id", value: messageID)])
    }
}
