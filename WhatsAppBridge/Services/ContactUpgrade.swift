import Foundation

struct ContactMessageInfo: Decodable {
    let messageID: String
    let accountID: String
    let chatJID: String
    let fromMe: Bool
    let createdAt: Int64
    let sentConfirmedAt: Int64?
    let deliveredAt: Int64?
    let readAt: Int64?
    let state: String
    let isGroup: Bool
    enum CodingKeys: String, CodingKey {
        case messageID = "message_id", accountID = "account_id", chatJID = "chat_jid"
        case fromMe = "from_me", createdAt = "created_at", sentConfirmedAt = "sent_confirmed_at"
        case deliveredAt = "delivered_at", readAt = "read_at", state, isGroup = "is_group"
    }
    static func date(_ timestamp: Int64?) -> Date? {
        guard let timestamp, timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp > 10_000_000_000 ? Double(timestamp) / 1000 : Double(timestamp))
    }
}

struct ContactBlockTarget: Decodable, Identifiable {
    let accountID: String
    let name: String
    let phone: String
    var id: String { accountID }
    enum CodingKeys: String, CodingKey { case accountID = "account_id", name, phone }
}
struct ContactBlockPlan: Decodable {
    let customerJID: String
    let targets: [ContactBlockTarget]
    enum CodingKeys: String, CodingKey { case customerJID = "customer_jid", targets }
    var phone: String { customerJID.components(separatedBy: "@").first ?? customerJID }
}
struct ContactBlockConfirmation: Decodable {
    let accountID: String
    let confirmed: Bool
    let blocked: Bool
    enum CodingKeys: String, CodingKey { case accountID = "account_id", confirmed, blocked }
    func matches(account: String, desired: Bool) -> Bool { confirmed && accountID == account && blocked == desired }
}
@MainActor enum ContactUpgradeAPI {
    private static func request<T: Decodable>(_ path: String, workspace: String, query: [URLQueryItem] = [], body: Data? = nil) async throws -> T {
        guard workspace != "signed-out", UserWorkspace.id == workspace else { throw CancellationError() }
        var parts = URLComponents(url: UserWorkspace.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { parts.queryItems = query }
        var request = URLRequest(url: parts.url!); request.timeoutInterval = 60
        if let body { request.httpMethod = "POST"; request.httpBody = body; request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()
        guard UserWorkspace.id == workspace else { throw CancellationError() }
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(T.self, from: data)
    }
    private struct BlockState: Decodable { let blocked: Bool }
    static func blocked(_ target: String, canonicalJID: String, workspace: String) async throws -> Bool {
        let value: BlockState = try await request("features/contact", workspace: workspace, query: [
            .init(name: "account_id", value: target), .init(name: "jid", value: canonicalJID)
        ])
        return value.blocked
    }
    static func info(_ message: Message, workspace: String) async throws -> ContactMessageInfo {
        let info: ContactMessageInfo = try await request("features/message-info", workspace: workspace, query: [
            .init(name: "account_id", value: message.accountID ?? "default"),
            .init(name: "chat_jid", value: message.chatJID),
            .init(name: "message_id", value: message.messageID)
        ])
        guard info.messageID == message.messageID, info.accountID == (message.accountID ?? "default"), info.chatJID == message.chatJID else { throw URLError(.cannotParseResponse) }
        return info
    }
    static func plan(_ conversation: Conversation, workspace: String) async throws -> ContactBlockPlan {
        try await request("features/contact-block-plan", workspace: workspace, query: [
            .init(name: "account_id", value: conversation.accountID ?? "default"),
            .init(name: "chat_jid", value: conversation.jid)
        ])
    }
    static func block(_ target: String, source: Conversation, desired: Bool, workspace: String) async throws {
        let payload: [String: Any] = ["source_account_id": source.accountID ?? "default", "chat_jid": source.jid, "target_account_id": target, "blocked": desired]
        let data = try JSONSerialization.data(withJSONObject: payload)
        let result: ContactBlockConfirmation = try await request("features/contact-block-account", workspace: workspace, body: data)
        guard result.matches(account: target, desired: desired) else { throw URLError(.cannotParseResponse) }
    }
}
