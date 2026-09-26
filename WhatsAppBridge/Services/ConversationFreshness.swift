import Foundation

enum ConversationFreshness {
    static func ageText(
        timestamp: Int64
    ) -> String {
        let date =
            Date(
                timeIntervalSince1970:
                    TimeInterval(
                        timestamp
                    )
            )

        let seconds =
            Date()
                .timeIntervalSince(
                    date
                )

        if seconds < 60 {
            return "Now"
        }

        if seconds < 3600 {
            return
                "\(Int(seconds / 60))m"
        }

        if seconds < 86_400 {
            return
                "\(Int(seconds / 3600))h"
        }

        if seconds <
            604_800 {

            return
                "\(Int(seconds / 86_400))d"
        }

        return date.formatted(
            date:
                .numeric,
            time:
                .omitted
        )
    }
}
