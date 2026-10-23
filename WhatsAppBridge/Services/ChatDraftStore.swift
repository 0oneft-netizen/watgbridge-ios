import Foundation
import Combine

@MainActor
final class ChatDraftStore: ObservableObject {
    @Published private(set) var revision = 0
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

        guard (defaults.string(forKey: storageKey) ?? "") != safeText else { return }
        revision &+= 1
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
        revision &+= 1
        defaults.removeObject(
            forKey: key(
                accountID: accountID,
                chatJID: chatJID
            )
        )
    }
}
