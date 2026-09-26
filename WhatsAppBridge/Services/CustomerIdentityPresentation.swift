import Foundation

enum CustomerIdentityPresentation {
    static func title(
        conversation:
            Conversation
    ) -> String {

        let name =
            conversation.name?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            ?? ""

        if !name.isEmpty {
            return name
        }

        let phone =
            ChatIdentity
                .customerPhone(
                    from:
                        conversation.jid
                )

        return phone.isEmpty
            ? "Customer"
            : phone
    }
}
