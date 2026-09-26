import Foundation

enum CustomerPhonePresentation {
    static func value(
        jid: String
    ) -> String {

        ChatIdentity
            .customerPhone(
                from:
                    jid
            )
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }
}
