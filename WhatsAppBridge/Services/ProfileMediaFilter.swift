import Foundation

enum ProfileMediaFilter {
    static func media(
        _ messages:
            [Message]
    ) -> [Message] {

        messages.filter {
            message in

            guard
                !MessageMediaPolicy
                    .isViewOnce(
                        message
                    )
            else {
                return false
            }

            switch message.type
                .lowercased() {

            case "image",
                 "video",
                 "gif",
                 "video_note":
                return true

            default:
                return false
            }
        }
    }

    static func documents(
        _ messages:
            [Message]
    ) -> [Message] {

        messages.filter {
            !MessageMediaPolicy
                .isViewOnce($0)
            &&
            $0.type
                .lowercased()
                ==
                "document"
        }
    }
}
