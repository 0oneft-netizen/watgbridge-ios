import Foundation

@MainActor
final class MessageSelectionStore:
    ObservableObject {

    @Published
    var selected =
        Set<Int64>()

    var isSelecting: Bool {
        !selected.isEmpty
    }

    func toggle(
        _ message: Message
    ) {
        if selected.contains(
            message.id
        ) {
            selected.remove(
                message.id
            )
        } else {
            guard
                MessageSelectionPolicy
                    .mayAdd(
                        currentCount:
                            selected.count
                    )
            else {
                return
            }

            selected.insert(
                message.id
            )
        }
    }

    func clear() {
        selected.removeAll()
    }
}
