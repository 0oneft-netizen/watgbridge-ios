import Foundation

enum SearchNormalization {
    static func value(
        _ text: String
    ) -> String {

        text
            .folding(
                options:
                    [
                        .caseInsensitive,
                        .diacriticInsensitive
                    ],
                locale:
                    .current
            )
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }

    static func matches(
        query: String,
        text: String
    ) -> Bool {

        let q =
            value(query)

        guard
            !q.isEmpty
        else {
            return true
        }

        return value(text)
            .contains(q)
    }
}
