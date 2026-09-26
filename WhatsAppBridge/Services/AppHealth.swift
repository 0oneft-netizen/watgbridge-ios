import Foundation

@MainActor
enum AppHealth {
    static func snapshot() ->
        AppHealthSnapshot {

        let sessions =
            SessionDirectory
                .shared
                .accounts

        let connected =
            sessions.filter {
                $0.status
                    .lowercased()
                    ==
                    "connected"
            }
            .count

        return
            AppHealthSnapshot(
                networkConnected:
                    NetworkMonitor
                        .shared
                        .isConnected,

                sessionCount:
                    sessions.count,

                connectedSessions:
                    connected,

                outboxCount:
                    PersistentOutbox
                        .shared
                        .items
                        .count
            )
    }
}
