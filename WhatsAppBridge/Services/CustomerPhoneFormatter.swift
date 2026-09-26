import Foundation

enum CustomerPhoneFormatter {
    static func digits(
        from jid: String
    ) -> String {
        let local =
            jid.split(
                separator: "@"
            )
            .first
            .map(String.init)
            ?? jid

        let withoutDevice =
            local.split(
                separator: ":"
            )
            .first
            .map(String.init)
            ?? local

        return withoutDevice
            .filter(\.isNumber)
    }

    static func display(
        from jid: String
    ) -> String {
        let value =
            digits(from: jid)

        guard !value.isEmpty else {
            return jid
        }

        return "+"
            + value
    }
}
