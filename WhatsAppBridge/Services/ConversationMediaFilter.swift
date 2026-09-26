import Foundation

enum ConversationMediaFilter:
    String,
    CaseIterable,
    Identifiable
{
    case media
    case documents
    case links

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .media:
            return "Media"
        case .documents:
            return "Docs"
        case .links:
            return "Links"
        }
    }

    func includes(
        _ message: Message
    ) -> Bool {
        switch self {
        case .media:
            return [
                "image",
                "video",
                "gif",
                "video_note",
                "ptv"
            ].contains(
                message.type.lowercased()
            )
            && !MessageMediaPolicy
                .isViewOnce(message)

        case .documents:
            return message.type
                .lowercased()
                == "document"

        case .links:
            return message.text
                .range(
                    of:
                        #"https?://[^\s]+"#,
                    options:
                        .regularExpression
                ) != nil
        }
    }
}
