import Foundation

enum SessionSorting {
    static func sorted(
        _ values:
            [SessionAccountDTO]
    ) -> [SessionAccountDTO] {

        values.sorted {
            left,
            right in

            let lp =
                priority(
                    left.status
                )

            let rp =
                priority(
                    right.status
                )

            if lp != rp {
                return lp < rp
            }

            return left
                .displayName
                .localizedCaseInsensitiveCompare(
                    right
                        .displayName
                )
                ==
                .orderedAscending
        }
    }

    private static func priority(
        _ status: String
    ) -> Int {
        switch status
            .lowercased() {

        case "reconnect_required":
            return 0

        case "disconnected":
            return 1

        case "connected":
            return 2

        default:
            return 3
        }
    }
}
