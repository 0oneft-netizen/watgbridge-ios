import Foundation

enum LogRedaction {
    static func route(
        accountID: String,
        chatJID: String
    ) -> String {
        let account =
            String(
                accountID
                    .suffix(6)
            )

        let chat =
            String(
                CustomerPhoneFormatter
                    .digits(
                        from:
                            chatJID
                    )
                    .suffix(4)
            )

        return
            "account=***\(account) chat=***\(chat)"
    }

    static func messageID(
        _ value: String
    ) -> String {
        guard
            value.count > 8
        else {
            return "***"
        }

        return
            "***"
            +
            String(
                value.suffix(8)
            )
    }
}
