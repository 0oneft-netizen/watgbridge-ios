import Foundation

final class APIClient {
    static let shared = APIClient()

    private init() {}

    // This will be replaced with our HTTPS address later.
    private let baseURL = URL(string: "https://5jjltkwg.tail256e07.ts.net")!

    func fetchConversations() async throws -> [Conversation] {
        let url = baseURL.appendingPathComponent("conversations")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Conversation].self, from: data)
    }

    func fetchMessages(chatJID: String) async throws -> [Message] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("messages"),
            resolvingAgainstBaseURL: false
        )!

        components.queryItems = [
            URLQueryItem(name: "chat_jid", value: chatJID)
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Message].self, from: data)
    }


    func sendMessage(chatJID: String, text: String) async throws {
        let url = baseURL.appendingPathComponent("send")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = [
            "chat_jid": chatJID,
            "text": text
        ]

        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

}
