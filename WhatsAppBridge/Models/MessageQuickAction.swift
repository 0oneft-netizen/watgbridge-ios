import Foundation

enum MessageQuickAction:
    String,
    Identifiable
{
    case reply
    case copy
    case react
    case deleteLocal
    case deleteEveryone

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .reply:
            return "Reply"
        case .copy:
            return "Copy"
        case .react:
            return "React"
        case .deleteLocal:
            return "Delete for Me"
        case .deleteEveryone:
            return "Delete for Everyone"
        }
    }

    var systemImage: String {
        switch self {
        case .reply:
            return "arrowshape.turn.up.left"
        case .copy:
            return "doc.on.doc"
        case .react:
            return "face.smiling"
        case .deleteLocal:
            return "trash"
        case .deleteEveryone:
            return "trash.slash"
        }
    }
}
