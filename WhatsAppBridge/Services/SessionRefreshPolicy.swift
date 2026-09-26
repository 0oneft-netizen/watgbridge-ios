import Foundation

actor SessionRefreshPolicy {
    static let shared =
        SessionRefreshPolicy()

    private var lastRefresh:
        Date?

    func shouldRefresh(
        minimumInterval:
            TimeInterval = 5
    ) -> Bool {

        let now =
            Date()

        if let lastRefresh,
           now.timeIntervalSince(
                lastRefresh
           )
           <
           minimumInterval {

            return false
        }

        self.lastRefresh =
            now

        return true
    }

    func invalidate() {
        lastRefresh = nil
    }
}
