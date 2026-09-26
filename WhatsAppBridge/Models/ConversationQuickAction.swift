import Foundation

enum ConversationQuickAction:
    String,
    Identifiable,
    CaseIterable
{
    case search
    case media
    case mute
    case archive

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .search:
            return "Search"
        case .media:
            return "Media"
        case .mute:
            return "Mute"
        case .archive:
            return "Archive"
        }
    }

    var systemImage: String {
        switch self {
        case .search:
            return "magnifyingglass"
        case .media:
            return "photo.on.rectangle"
        case .mute:
            return "bell.slash"
        case .archive:
            return "archivebox"
        }
    }
}
