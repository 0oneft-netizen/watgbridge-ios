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

        let normalized =
            value.lowercased()

        let genericNames: Set<String> = [
            "whatsapp contact",
            "whatsapp",
            "unknown contact",
            "unknown"
        ]

        // A real saved/contact name wins.
        // Generic WhatsApp placeholders and routing identifiers do not.
        if !value.isEmpty &&
            !genericNames.contains(normalized) &&
            !value.contains("@s.whatsapp.net") &&
            !value.hasSuffix("@lid") {
            return value
        }

        // Prefer the server-resolved real customer phone.
        let phone =
            customerPhone(
                conversation: conversation
            )

        if !phone.isEmpty {
            return phone
        }

        // Never expose an unresolved WhatsApp LID as a phone number.
        return "Unknown contact"
    }
}
