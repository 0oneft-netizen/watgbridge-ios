import Foundation

enum ComposerAttachment:
    String,
    Identifiable,
    CaseIterable
{
    case camera
    case photos
    case document

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .camera:
            return "Camera"
        case .photos:
            return "Photos"
        case .document:
            return "Document"
        }
    }

    var systemImage: String {
        switch self {
        case .camera:
            return "camera.fill"
        case .photos:
            return "photo.on.rectangle"
        case .document:
            return "doc.fill"
        }
    }
}
