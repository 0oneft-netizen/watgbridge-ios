import Foundation

enum MessageContentPolicy {
    static let previewLimit =
        500

    static func preview(
        _ value: String
    ) -> String {

        let normalized =
            value
                .replacingOccurrences(
                    of: "\r\n",
                    with: "\n"
                )
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard
            normalized.count >
                previewLimit
        else {
            return normalized
        }

        return String(
            normalized.prefix(
                previewLimit
            )
        )
        +
        "…"
    }
}
