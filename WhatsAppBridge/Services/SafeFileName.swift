import Foundation

enum SafeFileName {
    static func display(
        _ value: String?
    ) -> String {
        guard
            let value,
            !value.isEmpty
        else {
            return "Document"
        }

        return value
            .replacingOccurrences(
                of: "/",
                with: "-"
            )
            .replacingOccurrences(
                of: "\\",
                with: "-"
            )
    }
}
