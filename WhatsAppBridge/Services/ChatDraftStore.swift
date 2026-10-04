import Foundation

@MainActor
final class ChatDraftStore {
    static let shared = ChatDraftStore()

    private var defaults: UserDefaults { UserWorkspace.defaults }
    private let prefix = "chat.draft."

    private func key(
        accountID: String,
        chatJID: String
    ) -> String {
        prefix
        + accountID
        + "."
        + chatJID
    }

    func text(
        accountID: String,
        chatJID: String
    ) -> String {
        defaults.string(
            forKey: key(
                accountID: accountID,
                chatJID: chatJID
            )
        ) ?? ""
    }

    func save(
        _ text: String,
        accountID: String,
        chatJID: String
    ) {
        let storageKey = key(
            accountID: accountID,
            chatJID: chatJID
        )

        let safeText =
            ComposerTextPolicy
                .limited(text)

        if safeText.isEmpty {
            defaults.removeObject(
                forKey: storageKey
            )
        } else {
            defaults.set(
                safeText,
                forKey: storageKey
            )
        }
    }

    func clear(
        accountID: String,
        chatJID: String
    ) {
        defaults.removeObject(
            forKey: key(
                accountID: accountID,
                chatJID: chatJID
            )
        )
    }
}
