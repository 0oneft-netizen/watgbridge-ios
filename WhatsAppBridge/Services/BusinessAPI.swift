import Foundation

final class BusinessAPI {
    static let shared = BusinessAPI()

    private let base =
        "https://5jjltkwg.tail256e07.ts.net"

    private init() {}

    func customer(
        jid: String
    ) async throws -> BusinessCustomerMeta {
        var components =
            URLComponents(
                string: "\(base)/business/customer"
            )!

        components.queryItems = [
            URLQueryItem(
                name: "jid",
                value: jid
            )
        ]

        let (data, _) =
            try await URLSession.shared.data(
                from: components.url!
            )

        return try JSONDecoder().decode(
            BusinessCustomerMeta.self,
            from: data
        )
    }

    func saveCustomer(
        jid: String,
        label: String,
        note: String
    ) async throws {
        var components =
            URLComponents(
                string: "\(base)/business/customer"
            )!

        components.queryItems = [
            URLQueryItem(
                name: "jid",
                value: jid
            )
        ]

        var request =
            URLRequest(
                url: components.url!
            )

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "label": label,
                    "note": note
                ]
            )

        _ = try await
            URLSession.shared.data(
                for: request
            )
    }

    func quickReplies()
        async throws
        -> [BusinessQuickReply]
    {
        let url = URL(
            string:
                "\(base)/business/quick-replies"
        )!

        let (data, _) =
            try await URLSession.shared.data(
                from: url
            )

        return try JSONDecoder().decode(
            [BusinessQuickReply].self,
            from: data
        )
    }

    func saveQuickReply(
        shortcut: String,
        message: String
    ) async throws {
        let url = URL(
            string:
                "\(base)/business/quick-replies"
        )!

        var request =
            URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "shortcut": shortcut,
                    "message": message
                ]
            )

        _ = try await
            URLSession.shared.data(
                for: request
            )
    }
}
