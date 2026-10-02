import Foundation

struct MessageSyncBatch: Decodable {
    let cursor: Int64
    let reset: Bool
    let messages: [Message]
    let removed: [Int64]
}
extension APIClient {
    func mediaPreviewURL(for messageID: String, accountID: String?) -> URL? {
        var parts = URLComponents(url: baseURL.appendingPathComponent("media-preview"), resolvingAgainstBaseURL: false)
        parts?.queryItems = [URLQueryItem(name: "id", value: messageID), URLQueryItem(name: "account_id", value: accountID ?? "default")]
        return parts?.url
    }
    func syncMessages(chatJID: String, accountID: String, cursor: Int64?) async throws -> MessageSyncBatch {
        var parts = URLComponents(url: baseURL.appendingPathComponent("messages-sync"), resolvingAgainstBaseURL: false)!
        parts.queryItems = [URLQueryItem(name: "account_id", value: accountID), URLQueryItem(name: "chat_jid", value: chatJID)]
        if let cursor { parts.queryItems?.append(URLQueryItem(name: "after", value: String(cursor))) }
        guard let url = parts.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(MessageSyncBatch.self, from: data)
    }
}

enum MessageTimelineMerge {
    static func apply(_ batch: MessageSyncBatch, to existing: [Message]) -> [Message] {
        if batch.reset { return batch.messages }
        if batch.messages.isEmpty && batch.removed.isEmpty { return existing }
        let removed = Set(batch.removed)
        var rows = Dictionary(uniqueKeysWithValues: existing.filter { !removed.contains($0.id) }.map { ($0.id, $0) })
        for message in batch.messages { rows[message.id] = message }
        return rows.values.sorted {
            $0.createdAt == $1.createdAt ? $0.id < $1.id : $0.createdAt < $1.createdAt
        }
    }
}
