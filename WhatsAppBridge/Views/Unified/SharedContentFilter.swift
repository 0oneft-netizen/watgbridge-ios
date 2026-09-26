import Foundation

enum SharedContentFilter:
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
            return "Documents"
        case .links:
            return "Links"
        }
    }

    func includes(
        _ message: Message
    ) -> Bool {
        if MessageMediaPolicy.isViewOnce(message) {
            return false
        }

        let type =
            message.type
                .lowercased()

        switch self {
        case .media:
            return [
                "image",
                "video",
                "gif",
                "video_note",
                "ptv"
            ].contains(type)

        case .documents:
            return [
                "document",
                "file"
            ].contains(type)

        case .links:
            let text = message.text
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            guard !text.isEmpty else {
                return false
            }

            return text.range(
                of:
                    #"https?://[^\s]+"#,
                options:
                    [.regularExpression, .caseInsensitive]
            ) != nil
        }
    }
}
