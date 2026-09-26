import Foundation

enum ActiveChatSearch {
    static func results(
        query: String,
        messages:
            [Message]
    ) -> [Message] {

        ChatSearchEngine
            .results(
                query:
                    query,
                messages:
                    messages
            )
    }
}
