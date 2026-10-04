import Foundation
import Combine

struct CRMCustomer: Codable, Identifiable, Hashable {
    let id: Int64
    let accountID: String
    let jid: String
    let displayName: String
    let phone: String
    let sourceName: String
    let accountName: String
    let createdAt: Int64
    let updatedAt: Int64
    enum CodingKeys: String, CodingKey {
        case id, jid, phone
        case accountID = "account_id", displayName = "display_name"
        case sourceName = "source_name", accountName = "account_name"
        case createdAt = "created_at", updatedAt = "updated_at"
    }
    var conversation: Conversation {
        Conversation(accountID: accountID, jid: jid, name: displayName,
                     displayPhone: phone.isEmpty ? nil : phone,
                     lastMessage: "", lastMessageAt: updatedAt, unread: 0,
                     pinned: false, archived: false, muted: false)
    }
}
struct CRMGroup: Codable, Identifiable, Hashable {
    let id: Int64
    var name: String
    var welcomeMessage: String
    var autoSend: Bool
    let createdAt: Int64
    let updatedAt: Int64
    enum CodingKeys: String, CodingKey {
        case id, name
        case welcomeMessage = "welcome_message", autoSend = "auto_send"
        case createdAt = "created_at", updatedAt = "updated_at"
    }
    static let empty = CRMGroup(id: 0, name: "", welcomeMessage: "", autoSend: false, createdAt: 0, updatedAt: 0)
}
struct CRMMembership: Codable {
    let customerID: Int64
    let groupID: Int64
    let createdAt: Int64
    enum CodingKeys: String, CodingKey {
        case customerID = "customer_id", groupID = "group_id", createdAt = "created_at"
    }
}
struct CRMWelcomeJob: Codable, Identifiable {
    let id: Int64
    let customerID: Int64
    let groupID: Int64
    let state: String
    let messageID: String
    let lastError: String
    let attempts: Int
    enum CodingKeys: String, CodingKey {
        case id, state, attempts
        case customerID = "customer_id", groupID = "group_id"
        case messageID = "message_id", lastError = "last_error"
    }
    var statusText: String {
        switch state {
        case "pending": return "ממתין לשליחה"
        case "sending": return "שולח הודעה"
        case "sent": return "ההודעה נשלחה"
        case "failed": return "השליחה לא הושלמה"
        case "uncertain": return "מצב השליחה אינו ודאי"
        case "cancelled": return "השליחה בוטלה"
        default: return state
        }
    }
}
struct CRMState: Codable {
    var customers: [CRMCustomer]
    var groups: [CRMGroup]
    var memberships: [CRMMembership]
    var jobs: [CRMWelcomeJob]
    static let empty = CRMState(customers: [], groups: [], memberships: [], jobs: [])
}
struct CRMBackup: Codable {
    let formatVersion: Int
    let exportedAt: String
    let customers: [CRMCustomer]
    let groups: [CRMGroup]
    let memberships: [CRMMembership]
    enum CodingKeys: String, CodingKey {
        case formatVersion = "format_version", exportedAt = "exported_at"
        case customers, groups, memberships
    }
}
struct CRMError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class CustomerCRMAPI {
    static let shared = CustomerCRMAPI()
    private init() {}
    func request(_ path: String, method: String = "GET", body: Data? = nil, query: [URLQueryItem] = []) async throws -> CRMState {
        var parts = URLComponents(url: APIClient.shared.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { parts.queryItems = query }
        guard let url = parts.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CRMError(message: String(data: data, encoding: .utf8) ?? "שמירת הנתונים נכשלה")
        }
        return try JSONDecoder().decode(CRMState.self, from: data)
    }
}

@MainActor
final class CustomerCRMDirectory: ObservableObject {
    static let shared = CustomerCRMDirectory()
    @Published private(set) var state = CRMState.empty
    @Published private(set) var isSaving = false
    @Published var lastError: String?
    private var generation = 0
    private init() {}
    func resetForUser() { generation += 1; state = .empty; isSaving = false; lastError = nil }
    func customer(for conversation: Conversation) -> CRMCustomer? {
        state.customers.first { $0.accountID == (conversation.accountID ?? "default") && $0.jid == conversation.jid }
    }
    func name(for conversation: Conversation) -> String {
        customer(for: conversation)?.displayName ?? ChatIdentity.customerName(conversation: conversation)
    }
    func groupIDs(for customerID: Int64) -> Set<Int64> {
        Set(state.memberships.filter { $0.customerID == customerID }.map(\.groupID))
    }
    func refresh() async {
        let current = generation
        do {
            let result = try await CustomerCRMAPI.shared.request("crm/state")
            guard current == generation, !isSaving else { return }
            state = result
            lastError = nil
        } catch {
            if current == generation { lastError = error.localizedDescription }
        }
    }
    private func mutate(_ path: String, method: String = "POST", body: Data? = nil, query: [URLQueryItem] = []) async throws {
        guard !isSaving else { throw CRMError(message: "שמירה אחרת עדיין מתבצעת") }
        isSaving = true
        generation += 1
        let current = generation
        defer { if current == generation { isSaving = false } }
        let result = try await CustomerCRMAPI.shared.request(path, method: method, body: body, query: query)
        guard current == generation else { throw CancellationError() }
        state = result
        lastError = nil
        NotificationCenter.default.post(name: .bridgeRealtimeUpdate, object: nil)
    }
    func save(conversation: Conversation, name: String, groups: Set<Int64>) async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "account_id": conversation.accountID ?? "default", "jid": conversation.jid,
            "display_name": name, "group_ids": Array(groups).sorted()
        ])
        try await mutate("crm/customer", body: body)
    }
    func save(group: CRMGroup) async throws {
        try await mutate("crm/groups", body: JSONEncoder().encode(group))
    }
    func delete(group: CRMGroup) async throws {
        try await mutate("crm/groups", method: "DELETE", query: [URLQueryItem(name: "id", value: String(group.id))])
    }
    func retry(job: CRMWelcomeJob) async throws {
        try await mutate("crm/retry", body: JSONSerialization.data(withJSONObject: ["id": job.id, "confirm_possible_duplicate": true]))
    }
    func backup(groupID: Int64? = nil) throws -> Data {
        let selectedGroups = state.groups.filter { groupID == nil || $0.id == groupID }
        let selectedMembers = state.memberships.filter { groupID == nil || $0.groupID == groupID }
        let ids = Set(selectedMembers.map(\.customerID))
        let selectedCustomers = state.customers.filter { groupID == nil || ids.contains($0.id) }
        let backup = CRMBackup(formatVersion: 1, exportedAt: ISO8601DateFormatter().string(from: Date()),
                               customers: selectedCustomers, groups: selectedGroups, memberships: selectedMembers)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }
    func restore(data: Data) async throws {
        let backup = try JSONDecoder().decode(CRMBackup.self, from: data)
        guard backup.formatVersion == 1 else { throw CRMError(message: "גרסת קובץ גיבוי אינה נתמכת") }
        try await mutate("crm/import", body: JSONEncoder().encode(backup))
    }
}
