import Foundation

enum SearchPresentation {
    static func normalized(
        _ value: String
    ) -> String {
        value
            .folding(
                options: [
                    .caseInsensitive,
                    .diacriticInsensitive
                ],
                locale: .current
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    static func matches(
        message: Message,
        query: String
    ) -> Bool {
        let q = normalized(query)

        guard !q.isEmpty else {
            return true
        }

        return normalized(
            message.text
        ).contains(q)
        || normalized(
            message.fileName ?? ""
        ).contains(q)
    }
}
