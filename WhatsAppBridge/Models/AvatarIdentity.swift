import Foundation

struct AvatarIdentity:
    Hashable {

    let accountID: String
    let jid: String

    init(
        accountID: String?,
        jid: String
    ) {
        let route =
            ConversationRoute(
                accountID:
                    accountID,
                chatJID:
                    jid
            )

        self.accountID =
            route.accountID

        self.jid =
            route.chatJID
    }

    var cacheKey: String {
        accountID
        + "|"
        + jid
    }
}
