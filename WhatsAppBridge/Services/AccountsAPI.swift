import Foundation

final class AccountsAPI {
    static let shared = AccountsAPI()

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
            try await URLSession.shared.data(
                from: url
            )

        return try JSONDecoder().decode(
            [WhatsAppAccount].self,
            from: data
        )
    }
}
