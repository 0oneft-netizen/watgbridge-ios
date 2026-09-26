import Foundation

enum ChatSearchEngine {
    static func results(
        query: String,
        messages: [Message]
    ) -> [Message] {

        let q =
            SearchNormalization
                .value(query)

        guard
            !q.isEmpty
        else {
            return []
        }

        return messages.filter {
            message in

            SearchNormalization
                .matches(
                    query: q,
                    text:
                        message.text
                )
            ||
            SearchNormalization
                .matches(
                    query: q,
                    text:
                        message.fileName
                        ?? ""
                )
        }
    }
}
