import Foundation

enum OutgoingTextPolicy {
    static let maximumCharacters =
        65_000

    static func normalized(
        _ value: String
    ) -> String {

        let cleaned =
            value
                .replacingOccurrences(
                    of: "\r\n",
                    with: "\n"
                )
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        return String(
            cleaned.prefix(
                maximumCharacters
            )
        )
    }

    static func maySend(
        _ value: String
    ) -> Bool {

        !normalized(value)
            .isEmpty
    }
}
