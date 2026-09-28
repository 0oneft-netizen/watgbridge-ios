import Foundation

enum ChatIdentity {
    static func customerPhone(
        from jid: String
    ) -> String {
        let trimmed =
            jid.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // LID is an internal WhatsApp identifier.
        // Never display its digits as a telephone number.
        if trimmed.hasSuffix("@lid") {
            return ""
        }

        let raw =
            trimmed
                .split(separator: "@")
                .first
                .map(String.init)
                ?? trimmed

        let withoutDevice =
            raw
                .split(separator: ":")
                .first
                .map(String.init)
                ?? raw

        guard
            !withoutDevice.isEmpty,
            withoutDevice.allSatisfy({
                $0.isNumber
            })
        else {
            return withoutDevice
        }

        return "+" + withoutDevice
    }

    static func customerPhone(
        conversation: Conversation
    ) -> String {
        let resolved =
            conversation.displayPhone?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            ?? ""

        if !resolved.isEmpty {
            return resolved
        }

        return customerPhone(
            from: conversation.jid
        )
    }

    static func customerName(
        conversation: Conversation
    ) -> String {
        let value =
            conversation.name
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        // Do not show routing JIDs as names.
        if !value.isEmpty &&
            !value.contains(
                "@s.whatsapp.net"
            ) &&
            !value.hasSuffix(
                "@lid"
            ) {
            return value
        }

        let phone =
            customerPhone(
                conversation: conversation
            )

        if !phone.isEmpty {
            return phone
        }

        // Resolver may not know a newly-created LID yet.
        // Better neutral UI than exposing the internal ID.
        return "WhatsApp contact"
    }
}
