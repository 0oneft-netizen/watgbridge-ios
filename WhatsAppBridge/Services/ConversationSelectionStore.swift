import Foundation

@MainActor
final class ConversationSelectionStore:
    ObservableObject {

    @Published
    private(set)
    var selected =
        Set<String>()

    func key(
        _ conversation:
            Conversation
    ) -> String {
        (conversation.accountID
            ?? "default")
        + "|"
        + conversation.jid
    }

    func contains(
        _ conversation:
            Conversation
    ) -> Bool {
        selected.contains(
            key(conversation)
        )
    }

    func toggle(
        _ conversation:
            Conversation
    ) {
        let k =
            key(conversation)

        if selected.contains(k) {
            selected.remove(k)
        } else {
            selected.insert(k)
        }
    }

    func clear() {
        selected.removeAll()
    }
}
