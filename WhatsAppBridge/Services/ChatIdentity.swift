import Foundation

enum ChatIdentity {
    static func customerPhone(
        from jid: String
    ) -> String {
        let raw = jid
            .split(separator: "@")
            .first
            .map(String.init)
            ?? jid

        let withoutDevice = raw
            .split(separator: ":")
            .first
            .map(String.init)
            ?? raw

        guard withoutDevice.allSatisfy({
            $0.isNumber
        }) else {
            return withoutDevice
        }

        if withoutDevice.hasPrefix("972"),
           withoutDevice.count >= 11 {
            return "+\(withoutDevice)"
        }

        return withoutDevice
    }

    static func customerName(
        conversation: Conversation
    ) -> String {
        let value = conversation.name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !value.isEmpty {
            return value
        }

        return customerPhone(
            from: conversation.jid
        )
    }
}
