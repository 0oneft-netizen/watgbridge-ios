import Foundation

actor MessageRefreshPolicy {
    static let shared =
        MessageRefreshPolicy()

    private var lastRefresh:
        [String: Date] = [:]

    func shouldRefresh(
        accountID: String,
        chatJID: String,
        minimumInterval:
            TimeInterval = 0.35
    ) -> Bool {

        let key =
            accountID
            + "|"
            + chatJID

        let now =
            Date()

        if let previous =
            lastRefresh[key],
           now.timeIntervalSince(
                previous
           )
           <
           minimumInterval {

            return false
        }

        lastRefresh[key] =
            now

        return true
    }
}
