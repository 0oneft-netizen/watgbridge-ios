import Foundation

enum SessionHealthResolver {
    static func resolve(
        accounts: [SessionAccountDTO]
    ) -> [SessionHealth] {
        accounts.map {
            SessionHealth(
                accountID:
                    $0.id,
                displayName:
                    $0.displayName,
                status:
                    $0.status,
                accountType:
                    $0.accountType
            )
        }
    }

    static func problemCount(
        accounts: [SessionAccountDTO]
    ) -> Int {
        resolve(
            accounts: accounts
        )
        .filter {
            $0.level != .healthy
        }
        .count
    }
}
