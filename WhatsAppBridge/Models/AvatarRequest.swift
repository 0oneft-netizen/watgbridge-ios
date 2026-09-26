import Foundation

struct AvatarRequest:
    Hashable {

    let accountID: String
    let jid: String

    init(
        accountID: String?,
        jid: String
    ) {
        let identity =
            AvatarIdentity(
                accountID:
                    accountID,
                jid:
                    jid
            )

        self.accountID =
            identity.accountID

        self.jid =
            identity.jid
    }

    var queryItems:
        [URLQueryItem] {

        [
            URLQueryItem(
                name:
                    "account_id",
                value:
                    accountID
            ),
            URLQueryItem(
                name:
                    "jid",
                value:
                    jid
            )
        ]
    }
}
