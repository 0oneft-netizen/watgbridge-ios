import Foundation

enum SessionDisplayNamePolicy {
    static let maximumLength =
        40

    static func normalized(
        _ value: String
    ) -> String {

        let cleaned =
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .replacingOccurrences(
                    of: "\n",
                    with: " "
                )

        return String(
            cleaned.prefix(
                maximumLength
            )
        )
    }

    static func maySave(
        _ value: String
    ) -> Bool {
        !normalized(value)
            .isEmpty
    }
}
