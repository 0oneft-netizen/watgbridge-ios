import Foundation

@MainActor
final class ChatScrollState:
    ObservableObject {

    @Published
    var isNearBottom = true

    @Published
    var unseenIncoming = 0

    func incomingMessage(
        fromMe: Bool
    ) {
        guard
            !fromMe,
            !isNearBottom
        else {
            return
        }

        unseenIncoming += 1
    }

    func reachedBottom() {
        isNearBottom = true
        unseenIncoming = 0
    }

    func leftBottom() {
        isNearBottom = false
    }
}
