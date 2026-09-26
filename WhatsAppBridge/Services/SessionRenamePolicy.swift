import Foundation

enum SessionRenamePolicy {
    static func normalized(
        _ value:
            String
    ) -> String {

        SessionDisplayNamePolicy
            .normalized(
                value
            )
    }

    static func mayRename(
        from old:
            String,
        to new:
            String
    ) -> Bool {

        let value =
            normalized(new)

        return !value.isEmpty
        &&
        value !=
            normalized(old)
    }
}
