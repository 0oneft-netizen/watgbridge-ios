import Foundation
import Combine

@MainActor
final class SessionDirectory: ObservableObject {
    static let shared = SessionDirectory()

    @Published
    private(set) var sessions: [String: SessionIdentity] = [:]

    @Published
    private(set) var isLoading = false

    private init() {}

    func session(
        for accountID: String?
    ) -> SessionIdentity? {
        sessions[accountID ?? "default"]
    }

    func name(
        for accountID: String?
    ) -> String {
        let key = accountID ?? "default"

        if let session = sessions[key] {
            return session.effectiveName
        }

        return key == "default"
            ? "Primary"
            : key
    }

    func refresh() async {
        guard !isLoading else {
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {
            let accounts =
                try await APIClient.shared
                    .fetchSessionAccounts()

            var next:
                [String: SessionIdentity] = [:]

            for account in accounts {
                next[account.id] =
                    SessionIdentity(
                        id: account.id,
                        name:
                            account.displayName
                            ?? "",
                        phone:
                            account.phone
                            ?? "",
                        jid:
                            account.jid
                            ?? "",
                        status:
                            account.status
                            ?? "unknown"
                    )
            }

            sessions = next
        } catch {
            print(
                "SessionDirectory refresh failed:",
                error.localizedDescription
            )
        }
    }
}
