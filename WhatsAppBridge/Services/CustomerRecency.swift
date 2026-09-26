import Foundation

enum CustomerRecencyLevel:
    Equatable {

    case recent
    case aging
    case stale
}

enum CustomerRecency {
    static func level(
        timestamp: Int64
    ) -> CustomerRecencyLevel {

        let date =
            Date(
                timeIntervalSince1970:
                    TimeInterval(
                        timestamp
                    )
            )

        let age =
            Date()
                .timeIntervalSince(
                    date
                )

        if age <
            86_400 {
            return .recent
        }

        if age <
            604_800 {
            return .aging
        }

        return .stale
    }
}
