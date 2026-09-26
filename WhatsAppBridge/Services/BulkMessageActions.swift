import Foundation

@MainActor
enum BulkMessageActions {
    static func star(
        messages: [Message]
    ) {
        for message in messages {
            if !StarredMessageStore
                .shared
                .contains(message) {

                StarredMessageStore
                    .shared
                    .toggle(message)
            }
        }
    }

    static func unstar(
        messages: [Message]
    ) {
        for message in messages {
            if StarredMessageStore
                .shared
                .contains(message) {

                StarredMessageStore
                    .shared
                    .toggle(message)
            }
        }
    }
}
