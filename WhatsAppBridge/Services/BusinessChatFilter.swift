import Foundation

enum BusinessChatFilter: String, CaseIterable, Identifiable {
    case all, unread, groups, drafts, attention
    var id: String { rawValue }
    var title: String {
        switch self { case .all: return "הכול"; case .unread: return "לא נקראו"; case .groups: return "קבוצות"; case .drafts: return "טיוטות"; case .attention: return "דורש בדיקה" }
    }
    func includes(_ conversation: Conversation, hasDraft: Bool = false, needsAttention: Bool = false) -> Bool {
        switch self {
        case .all: return true
        case .unread: return conversation.unread > 0
        case .groups: return conversation.jid.hasSuffix("@g.us")
        case .drafts: return hasDraft
        case .attention: return needsAttention
        }
    }
}
