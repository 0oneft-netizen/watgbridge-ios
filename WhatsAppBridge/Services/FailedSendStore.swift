import Foundation

struct FailedTextSend: Identifiable, Codable {
    let id: UUID
    let accountID: String
    let chatJID: String
    let text: String
    let createdAt: Date
}

@MainActor
final class FailedSendStore:
    ObservableObject {

    static let shared =
        FailedSendStore()

    @Published
    private(set)
    var items: [FailedTextSend] = []

    private init() {}

    func add(
        accountID: String,
        chatJID: String,
        text: String
    ) {
        guard
            !items.contains(
                where: {
                    $0.accountID ==
                        accountID &&
                    $0.chatJID ==
                        chatJID &&
                    $0.text == text
                }
            )
        else {
            return
        }

        items.append(
            FailedTextSend(
                id: UUID(),
                accountID: accountID,
                chatJID: chatJID,
                text: text,
                createdAt: Date()
            )
        )
    }

    func remove(
        id: UUID
    ) {
        items.removeAll {
            $0.id == id
        }
    }

    func items(
        accountID: String,
        chatJID: String
    ) -> [FailedTextSend] {
        items.filter {
            $0.accountID ==
                accountID &&
            $0.chatJID ==
                chatJID
        }
    }
    func reloadForUser() { items = [] }

}
