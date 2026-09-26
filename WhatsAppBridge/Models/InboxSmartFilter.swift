import Foundation

enum InboxSmartFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case unread
    case priority
    case waiting
    case followUp
    case archived

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .unread:
            return "Unread"
        case .priority:
            return "Priority"
        case .waiting:
            return "Waiting"
        case .followUp:
            return "Follow Up"
        case .archived:
            return "Archived"
        }
    }
}
