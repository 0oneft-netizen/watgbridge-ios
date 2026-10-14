import Foundation

enum BusinessChatFilter: String, CaseIterable, Identifiable {
    case all, unread, groups
    var id: String { rawValue }
    var title: String {
        switch self { case .all: return "הכול"; case .unread: return "לא נקראו"; case .groups: return "קבוצות" }
    }
    func includes(_ conversation: Conversation) -> Bool {
        switch self {
        case .all: return true
        case .unread: return conversation.unread > 0
        case .groups: return conversation.jid.hasSuffix("@g.us")
        }
    }
}
