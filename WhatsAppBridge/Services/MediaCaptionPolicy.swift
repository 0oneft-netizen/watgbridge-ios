import Foundation

enum MediaCaptionPolicy {
    static let maximumLength =
        4_096

    static func normalized(
        _ caption: String
    ) -> String {
        let value =
            caption
                .replacingOccurrences(
                    of: "\r\n",
                    with: "\n"
                )

        return String(
            value.prefix(
                maximumLength
            )
        )
    }
}
