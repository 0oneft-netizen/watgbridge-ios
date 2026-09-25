import Foundation

final class APIClient {
    static let shared = APIClient()

    private init() {}

    // This will be replaced with our HTTPS address later.
    let baseURL = URL(string: "https://5jjltkwg.tail256e07.ts.net")!

    func fetchConversations() async throws -> [Conversation] {
        let url = baseURL.appendingPathComponent("conversations")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Conversation].self, from: data)
    }

    func fetchMessages(chatJID: String, accountID: String = "default") async throws -> [Message] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("messages-v2"),
            resolvingAgainstBaseURL: false
        )!

        components.queryItems = [
            URLQueryItem(name: "chat_jid", value: chatJID),
            URLQueryItem(name: "account_id", value: accountID)
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


    func sendMessage(chatJID: String, text: String, accountID: String = "default") async throws {
        let url = baseURL.appendingPathComponent("send")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = [
            "account_id": accountID,
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


    func avatarURL(for jid: String) -> URL? {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("avatar"),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = [
            URLQueryItem(name: "jid", value: jid)
        ]

        return components?.url
    }


    func markRead(
        chatJID: String,
        accountID: String = "default"
    ) async throws {
        let url = baseURL.appendingPathComponent("mark-read")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try JSONSerialization.data(
            withJSONObject: [
                "account_id": accountID,
                "chat_jid": chatJID
            ]
        )

        let (_, response) = try await URLSession.shared.data(
            for: request
        )

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }


    func sendMedia(
        chatJID: String,
        type: String,
        data: Data,
        filename: String,
        mimeType: String,
        caption: String = "",
        accountID: String = "default"
    ) async throws {

        let url = baseURL.appendingPathComponent("send-media-v2")

        let boundary =
            "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()

        func addField(
            _ name: String,
            _ value: String
        ) {
            body.append(
                "--\(boundary)\r\n".data(
                    using: .utf8
                )!
            )

            body.append(
                "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
                    .data(using: .utf8)!
            )

            body.append(
                "\(value)\r\n".data(
                    using: .utf8
                )!
            )
        }

        addField("chat_jid", chatJID)
        addField("type", type)
        addField("caption", caption)
        addField("mime_type", mimeType)

        body.append(
            "--\(boundary)\r\n".data(
                using: .utf8
            )!
        )

        body.append(
            """
            Content-Disposition: form-data; name="file"; filename="\(filename)"\r
            Content-Type: \(mimeType)\r
            \r
            """.data(using: .utf8)!
        )

        body.append(data)

        body.append(
            "\r\n--\(boundary)--\r\n".data(
                using: .utf8
            )!
        )

        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(
            for: request
        )

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }


    func mediaURL(
        for messageID: String,
        accountID: String? = nil
    ) -> URL? {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("media"),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = [
            URLQueryItem(
                name: "id",
                value: messageID
            ),
            URLQueryItem(
                name: "account_id",
                value: accountID ?? "default"
            )
        ]

        return components?.url
    }


    func react(
        messageID: String,
        chatJID: String,
        emoji: String
    ,
        accountID: String = "default") async throws {

        let url =
            baseURL.appendingPathComponent("reaction")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try JSONSerialization.data(
            withJSONObject: [
                "message_id": messageID,
                "chat_jid": chatJID,
                "emoji": emoji
            ]
        )

        let (_, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let http =
                response as? HTTPURLResponse,
              (200...299).contains(
                http.statusCode
              )
        else {
            throw URLError(
                .badServerResponse
            )
        }
    }

    func deleteLocal(
        messageID: String,
        accountID: String = "default"
    ) async throws {

        let url =
            baseURL.appendingPathComponent(
                "delete-local"
            )

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "message_id": messageID
                ]
            )

        let (_, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let http =
                response as? HTTPURLResponse,
              (200...299).contains(
                http.statusCode
              )
        else {
            throw URLError(
                .badServerResponse
            )
        }
    }

    func searchMessages(
        chatJID: String,
        query: String
    ) async throws -> [Message] {

        var components = URLComponents(
            url:
                baseURL.appendingPathComponent(
                    "search-messages"
                ),
            resolvingAgainstBaseURL:
                false
        )

        components?.queryItems = [
            URLQueryItem(
                name: "chat_jid",
                value: chatJID
            ),
            URLQueryItem(
                name: "q",
                value: query
            )
        ]

        guard let url =
                components?.url
        else {
            return []
        }

        let (data, _) =
            try await URLSession.shared.data(
                from: url
            )

        return try JSONDecoder()
            .decode(
                [Message].self,
                from: data
            )
    }


    func sendReply(
        chatJID: String,
        text: String,
        replyTo: Message,
        accountID: String = "default"
    ) async throws {

        let url =
            baseURL.appendingPathComponent(
                "send-reply"
            )

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "chat_jid": chatJID,
                    "text": text,
                    "reply_message_id":
                        replyTo.messageID,
                    "reply_sender_jid":
                        replyTo.senderJID,
                    "reply_text":
                        replyTo.text.isEmpty
                        ? replyTo.type
                        : replyTo.text
                ]
            )

        let (_, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let http =
                response as? HTTPURLResponse,
              (200...299).contains(
                http.statusCode
              )
        else {
            throw URLError(
                .badServerResponse
            )
        }
    }

    func deleteForEveryone(
        chatJID: String,
        messageID: String
    ) async throws {

        let url =
            baseURL.appendingPathComponent(
                "delete-everyone"
            )

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "chat_jid": chatJID,
                    "message_id": messageID
                ]
            )

        let (_, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let http =
                response as? HTTPURLResponse,
              (200...299).contains(
                http.statusCode
              )
        else {
            throw URLError(
                .badServerResponse
            )
        }
    }


    func conversationAction(
        chatJID: String,
        action: String,
        value: Bool,
        accountID: String = "default"
    ) async throws {

        let url =
            baseURL.appendingPathComponent(
                "conversation-action"
            )

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "account_id": accountID,
                    "chat_jid": chatJID,
                    "action": action,
                    "value": value
                ]
            )

        let (_, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let http =
                response as? HTTPURLResponse,
              (200...299).contains(
                http.statusCode
              )
        else {
            throw URLError(
                .badServerResponse
            )
        }
    }

}

extension APIClient {
    func renameAccount(
        accountID: String,
        displayName: String
    ) async throws {
        let url = baseURL
            .appendingPathComponent(
                "accounts/rename"
            )

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Content-Type"
        )

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "account_id": accountID,
                    "display_name": displayName
                ]
            )

        let (_, response) =
            try await URLSession.shared
                .data(for: request)

        guard let http =
            response as? HTTPURLResponse,
              (200...299).contains(
                http.statusCode
              )
        else {
            throw URLError(
                .badServerResponse
            )
        }
    }
}
