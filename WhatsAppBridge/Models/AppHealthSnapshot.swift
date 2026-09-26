import Foundation

struct AppHealthSnapshot {
    Equatable {

    let networkConnected: Bool
    let sessionCount: Int
    let connectedSessions: Int
    let outboxCount: Int

    var hasProblems: Bool {
        !networkConnected
        ||
        connectedSessions
            <
            sessionCount
        ||
        outboxCount > 0
    }
}
