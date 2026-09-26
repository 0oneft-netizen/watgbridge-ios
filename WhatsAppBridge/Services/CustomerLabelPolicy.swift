import Foundation

enum CustomerLabelPolicy {
    static let maximumLabels =
        12

    static let maximumLength =
        24

    static func normalized(
        _ value: String
    ) -> String {

        String(
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .prefix(
                    maximumLength
                )
        )
    }

    static func mayAdd(
        value: String,
        current:
            [String]
    ) -> Bool {

        let label =
            normalized(value)

        guard
            !label.isEmpty,
            current.count <
                maximumLabels
        else {
            return false
        }

        return !current.contains {
            $0.caseInsensitiveCompare(
                label
            )
            ==
            .orderedSame
        }
    }
}
