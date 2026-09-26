import Foundation

enum ConversationBulkAction {
    Hashable {

    case markUnread
    case archive
    case priority
    case done

    var title: String {
        switch self {
        case .markUnread:
            return "Mark Unread"
        case .archive:
            return "Archive"
        case .priority:
            return "Priority"
        case .done:
            return "Mark Done"
        }
    }

    var systemImage:
        String {
        switch self {
        case .markUnread:
            return "envelope.badge"
        case .archive:
            return "archivebox"
        case .priority:
            return "exclamationmark.circle"
        case .done:
            return "checkmark.circle"
        }
    }
}
