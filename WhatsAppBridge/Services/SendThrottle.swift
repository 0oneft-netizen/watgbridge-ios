import Foundation

actor SendThrottle {
    static let shared =
        SendThrottle()

    private var lastSend:
        [String: Date] = [:]

    func maySend(
        accountID: String,
        chatJID: String
    ) -> Bool {
        let key =
            accountID
            + "|"
            + chatJID

        let now = Date()

        if let previous =
            lastSend[key],
           now.timeIntervalSince(
                previous
           ) < 0.25 {

            return false
        }

        lastSend[key] =
            now

        return true
    }
}
