import Foundation

@MainActor
enum FollowUpSorting {
    static func conversations(
        _ values:
            [Conversation]
    ) -> [Conversation] {

        let store =
            CustomerFollowUpStore
                .shared

        return values.sorted {
            left,
            right in

            let l =
                store.value(
                    for: left
                )?
                .dueAt

            let r =
                store.value(
                    for: right
                )?
                .dueAt

            switch (l, r) {
            case let (a?, b?):
                return a < b

            case (_?, nil):
                return true

            case (nil, _?):
                return false

            default:
                return false
            }
        }
    }
}
