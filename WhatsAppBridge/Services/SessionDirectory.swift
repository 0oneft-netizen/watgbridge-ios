import Foundation
import Combine

@MainActor
final class SessionDirectory: ObservableObject {
    static let shared = SessionDirectory()

    @Published
    private(set) var sessions: [String: SessionIdentity] = [:]

    @Published
    private(set) var isLoading = false

    private var generation = 0
    private init() {}
    func resetForUser() { generation += 1; sessions = [:]; isLoading = false }

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
        let current = generation

        defer {
            if generation == current { isLoading = false }
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
                            ?? "unknown",
                        accountType:
                            account.accountType
                            ?? "regular"
                    )
            }

            guard current == generation else { return }
            sessions = next
        } catch {
            print(
                "SessionDirectory refresh failed:",
                error.localizedDescription
            )
        }
    }
}
