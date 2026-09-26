import Foundation

actor OutgoingActionGuard {
    static let shared =
        OutgoingActionGuard()

    private var active =
        Set<String>()

    func begin(
        _ intent:
            OutgoingSendIntent
    ) -> Bool {

        guard
            !active.contains(
                intent.key
            )
        else {
            return false
        }

        active.insert(
            intent.key
        )

        return true
    }

    func finish(
        _ intent:
            OutgoingSendIntent
    ) {
        active.remove(
            intent.key
        )
    }

    func reset() {
        active.removeAll()
    }
}
