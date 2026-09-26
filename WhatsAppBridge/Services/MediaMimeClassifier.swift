import Foundation

enum MediaMimeClass:
    Equatable {

    case image
    case video
    case audio
    case document
    case unknown
}

enum MediaMimeClassifier {
    static func classify(
        _ mime:
            String?
    ) -> MediaMimeClass {

        let value =
            mime?
                .lowercased()
            ?? ""

        if value.hasPrefix(
            "image/"
        ) {
            return .image
        }

        if value.hasPrefix(
            "video/"
        ) {
            return .video
        }

        if value.hasPrefix(
            "audio/"
        ) {
            return .audio
        }

        if !value.isEmpty {
            return .document
        }

        return .unknown
    }
}
