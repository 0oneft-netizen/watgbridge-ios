import Foundation

enum ConversationMediaKind:
    String,
    CaseIterable,
    Identifiable {

    case all
    case photos
    case videos

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .photos:
            return "Photos"
        case .videos:
            return "Videos"
        }
    }
}

enum ConversationMediaFilter {
    static func filter(
        _ messages: [Message],
        kind:
            ConversationMediaKind
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

            switch kind {
            case .all:
                return [
                    "image",
                    "video",
                    "gif",
                    "video_note",
                    "ptv"
                ]
                .contains(
                    message.type
                        .lowercased()
                )

            case .photos:
                return [
                    "image",
                    "gif"
                ]
                .contains(
                    message.type
                        .lowercased()
                )

            case .videos:
                return [
                    "video",
                    "video_note",
                    "ptv"
                ]
                .contains(
                    message.type
                        .lowercased()
                )
            }
        }
    }
}
