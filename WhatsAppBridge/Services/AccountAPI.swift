import Foundation

final class AccountAPI {
    static let shared = AccountAPI()

    private let base =
        "https://5jjltkwg.tail256e07.ts.net"

    private init() {}

    func accounts()
        async throws
        -> [WhatsAppAccount]
    {
        let url = URL(
            string: "\(base)/accounts"
        )!

        let (data, _) =
            try await URLSession.shared
                .data(from: url)

        return try JSONDecoder()
            .decode(
                [WhatsAppAccount].self,
                from: data
            )
    }

    func createAccount(
        type: WhatsAppConnectionType
    ) async throws -> String {
        var components = URLComponents(
            string: "\(base)/accounts"
        )!

        components.queryItems = [
            URLQueryItem(
                name: "type",
                value: type.rawValue
            )
        ]

        var request = URLRequest(
            url: components.url!
        )

        request.httpMethod = "POST"

        let (data, response) =
            try await URLSession.shared
                .data(for: request)

        if let http =
            response as? HTTPURLResponse,
           !(200...299).contains(
                http.statusCode
           )
        {
            throw URLError(
                .badServerResponse
            )
        }

        let object =
            try JSONSerialization
                .jsonObject(
                    with: data
                ) as? [String: Any]

        guard let id =
            object?["id"] as? String
        else {
            throw URLError(
                .cannotParseResponse
            )
        }

        return id
    }

    func status(
        id: String
    ) async throws
        -> WhatsAppAccountStatus
    {
        var c =
            URLComponents(
                string:
                    "\(base)/accounts/status"
            )!

        c.queryItems = [
            URLQueryItem(
                name: "id",
                value: id
            )
        ]

        let (data, _) =
            try await URLSession.shared
                .data(
                    from: c.url!
                )

        return try JSONDecoder()
            .decode(
                WhatsAppAccountStatus.self,
                from: data
            )
    }

    func qr(
        id: String
    ) async throws
        -> WhatsAppQRResponse
    {
        var c =
            URLComponents(
                string:
                    "\(base)/accounts/qr"
            )!

        c.queryItems = [
            URLQueryItem(
                name: "id",
                value: id
            )
        ]

        let (data, _) =
            try await URLSession.shared
                .data(
                    from: c.url!
                )

        return try JSONDecoder()
            .decode(
                WhatsAppQRResponse.self,
                from: data
            )
    }
}
