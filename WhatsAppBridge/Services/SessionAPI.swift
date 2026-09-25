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
