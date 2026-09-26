import Foundation

enum CustomerIdentityPresentation {
    static func cleanPhone(
        from jid: String
    ) -> String {
        let raw = jid
            .replacingOccurrences(
                of: "@s.whatsapp.net",
                with: ""
            )
            .replacingOccurrences(
                of: "@lid",
                with: ""
            )
            .replacingOccurrences(
                of: "@g.us",
                with: ""
            )

        return raw
            .split(separator: ":")
            .first
            .map(String.init)
            ?? raw
    }

    static func formattedPhone(
        from jid: String
    ) -> String {
        let value = cleanPhone(
            from: jid
        )

        guard
            !value.isEmpty,
            value.allSatisfy(\.isNumber)
        else {
            return value
        }

        return value.hasPrefix("+")
            ? value
            : "+" + value
    }
}
