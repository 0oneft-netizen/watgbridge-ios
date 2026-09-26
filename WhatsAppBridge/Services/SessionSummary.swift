import Foundation

struct SessionSummary {
    let total: Int
    let connected: Int
    let business: Int

    init(
        sessions: [SessionIdentity]
    ) {
        total = sessions.count

        connected =
            sessions.filter(
                \.isConnected
            ).count

        business =
            sessions.filter {
                $0.accountType
                    .lowercased()
                    == "business"
            }.count
    }
}
