import Foundation

enum AvatarCacheKey {
    static func value(
        accountID: String?,
        jid: String
    ) -> String {

        AvatarIdentity(
            accountID:
                accountID,
            jid:
                jid
        )
        .cacheKey
    }
}
