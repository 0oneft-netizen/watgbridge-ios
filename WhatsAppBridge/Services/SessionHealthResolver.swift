import Foundation

enum SessionHealthResolver {
    static func resolve(
        accounts: [SessionIdentity]
    ) -> [SessionHealth] {
        accounts.map {
            SessionHealth(
                accountID: $0.id,
                displayName: $0.effectiveName,
                status: $0.status,
                accountType: $0.accountType
            )
        }
    }

    static func problemCount(
        accounts: [SessionIdentity]
    ) -> Int {
        resolve(accounts: accounts)
            .filter {
                $0.level != .healthy
            }
            .count
    }
}
