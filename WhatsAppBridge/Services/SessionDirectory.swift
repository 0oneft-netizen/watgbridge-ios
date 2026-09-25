import Foundation
import Combine

@MainActor
final class SessionDirectory: ObservableObject {
    static let shared = SessionDirectory()

    @Published
    private(set) var sessions: [String: SessionIdentity] = [:]

    private init() {}

    func replace(with accounts: [WhatsAppAccount]) {
        var result: [String: SessionIdentity] = [:]

        for account in accounts {
            result[account.id] = SessionIdentity(
                id: account.id,
                name: account.displayName,
                phone: account.phone ?? "",
                jid: account.jid ?? "",
                status: account.status
            )
        }

        sessions = result
    }

    func session(
        for accountID: String?
    ) -> SessionIdentity? {
        sessions[accountID ?? "default"]
    }

    func name(
        for accountID: String?
    ) -> String {
        session(for: accountID)?
            .effectiveName
        ?? accountID
        ?? "default"
    }

    func phone(
        for accountID: String?
    ) -> String {
        session(for: accountID)?
            .formattedPhone
        ?? ""
    }
}
