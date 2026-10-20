import Foundation

struct HiddenSentMessage: Decodable, Identifiable {
    let messageID: String
    let text: String
    let kind: String
    let createdAt: Int64
    var id: String { messageID }
    enum CodingKeys: String, CodingKey {
        case messageID = "message_id", text, kind = "message_type", createdAt = "created_at"
    }
}

@MainActor enum MessageDeleteAPI {
    private struct Result: Decodable { let ok: Bool }
    static func remove(account: String, chat: String, message: String, everyone: Bool, workspace: String) async throws {
        let result: Result = try await UltraCompleteAPI.request(everyone ? "delete-everyone" : "delete-local",
            workspace: workspace, method: "POST",
            body: ["account_id": account, "chat_jid": chat, "message_id": message], timeout: 25)
        guard result.ok else { throw URLError(.badServerResponse) }
    }
    static func hidden(account: String, chat: String, workspace: String) async throws -> [HiddenSentMessage] {
        try await UltraCompleteAPI.request("delete-local", workspace: workspace,
            query: [.init(name: "account_id", value: account), .init(name: "chat_jid", value: chat)])
    }
}
