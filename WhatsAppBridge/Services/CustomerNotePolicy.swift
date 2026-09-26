import Foundation

enum CustomerNotePolicy {
    static let maximumLength =
        4_000

    static func normalized(
        _ value: String
    ) -> String {

        String(
            value
                .replacingOccurrences(
                    of: "\r\n",
                    with: "\n"
                )
                .prefix(
                    maximumLength
                )
        )
    }
}
