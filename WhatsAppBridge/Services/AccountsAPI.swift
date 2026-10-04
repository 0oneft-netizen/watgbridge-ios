import Foundation

final class AccountsAPI {
    static let shared = AccountsAPI()

    private var base: String { UserWorkspace.baseURL.absoluteString }

    private init() {}

    func accounts()
        async throws
        -> [WhatsAppAccount]
    {
        let url = URL(
            string: "\(base)/accounts"
        )!

        let (data, _) =
            try await URLSession.shared.data(
                from: url
            )

        return try JSONDecoder().decode(
            [WhatsAppAccount].self,
            from: data
        )
    }
}
