import Foundation

final class PushRegistration {
    static let shared = PushRegistration()

    private init() {}

    func register(token: String) async {
        guard let url = URL(
            string: "https://5jjltkwg.tail256e07.ts.net/push/register"
        ) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.httpBody = try? JSONSerialization.data(
            withJSONObject: [
                "token": token
            ]
        )

        _ = try? await URLSession.shared.data(
            for: request
        )
    }
}
