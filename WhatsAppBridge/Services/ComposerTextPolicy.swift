import Foundation

enum ComposerTextPolicy {
    static let maximumLength =
        16_000

    static func normalized(
        _ text: String
    ) -> String {
        text.replacingOccurrences(
            of: "\r\n",
            with: "\n"
        )
    }

    static func limited(
        _ text: String
    ) -> String {
        let normalized =
            normalized(text)

        guard
            normalized.count >
                maximumLength
        else {
            return normalized
        }

        return String(
            normalized.prefix(
                maximumLength
            )
        )
    }

    static func maySend(
        _ text: String
    ) -> Bool {
        !text.trimmingCharacters(
            in:
                .whitespacesAndNewlines
        )
        .isEmpty
    }
}
