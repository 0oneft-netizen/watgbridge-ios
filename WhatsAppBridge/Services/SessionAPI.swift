import Foundation

extension APIClient {
    func fetchSessionAccounts()
        async throws -> [SessionAccountDTO] {

        let url = baseURL
            .appendingPathComponent(
                "accounts"
            )

        let (data, response) =
            try await URLSession.shared
                .data(from: url)

        guard
            let http =
                response as? HTTPURLResponse,
            (200...299).contains(
                http.statusCode
            )
        else {
            throw URLError(
                .badServerResponse
            )
        }

        let decoder = JSONDecoder()

        if let direct =
            try? decoder.decode(
                [SessionAccountDTO].self,
                from: data
            ) {
            return direct
        }

        struct Wrapper: Codable {
            let accounts:
                [SessionAccountDTO]
        }

        return try decoder.decode(
            Wrapper.self,
            from: data
        ).accounts
    }
}

extension APIClient {
    func disconnectSession(
        accountID: String
    ) async throws {
        let url = baseURL
            .appendingPathComponent(
                "accounts/disconnect"
            )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: [
                    "account_id": accountID
                ]
            )

        let (data, response) =
            try await URLSession.shared
                .data(for: request)

        guard let http =
                response as? HTTPURLResponse,
              (200...299).contains(
                http.statusCode
              )
        else {
            let message =
                String(
                    data: data,
                    encoding: .utf8
                ) ?? "Disconnect failed"

            throw NSError(
                domain: "SessionDisconnect",
                code:
                    (response as? HTTPURLResponse)?
                        .statusCode ?? -1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        message
                ]
            )
        }
    }
}

