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

        #if DEBUG
        let environment = "development"
        #else
        let environment = "production"
        #endif

        let bundleID =
            Bundle.main.bundleIdentifier
            ?? "com.watgbridge.ios"

        request.httpBody = try? JSONSerialization.data(
            withJSONObject: [
                "token": token,
                "environment": environment,
                "bundle_id": bundleID
            ]
        )

        _ = try? await URLSession.shared.data(
            for: request
        )
    }
}
