import Foundation

enum MessageAction:
    Hashable {

    case reply
    case copy
    case star
    case forward
    case info
    case deleteLocal
    case deleteEveryone

    var title: String {
        switch self {
        case .reply:
            return "Reply"
        case .copy:
            return "Copy"
        case .star:
            return "Star"
        case .forward:
            return "Forward"
        case .info:
            return "Info"
        case .deleteLocal:
            return "Delete for me"
        case .deleteEveryone:
            return "Delete for everyone"
        }
    }

    var systemImage:
        String {
        switch self {
        case .reply:
            return "arrowshape.turn.up.left"
        case .copy:
            return "doc.on.doc"
        case .star:
            return "star"
        case .forward:
            return "arrowshape.turn.up.right"
        case .info:
            return "info.circle"
        case .deleteLocal,
             .deleteEveryone:
            return "trash"
        }
    }
}
