import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Shared by the iOS save path and the native macOS ImageIO regression tests.
// The file's actual container determines its type; its extension is never trusted.
enum PhotoExportEncoder {
    struct PreparedImage: Sendable {
        let data: Data
        let typeIdentifier: String
        let fileExtension: String
    }
    enum ExportError: LocalizedError {
        case invalidImage, tooLarge, encodingFailed
        var errorDescription: String? {
            switch self {
            case .invalidImage: return "הקובץ שהתקבל אינו תמונה תקינה. התמונה לא נשמרה בגלריה."
            case .tooLarge: return "התמונה גדולה מדי לשמירה בטוחה במכשיר."
            case .encodingFailed: return "לא ניתן להכין את התמונה לשמירה בגלריה."
            }
        }
    }
    static func prepare(file: URL) throws -> PreparedImage {
        guard file.isFileURL else { throw ExportError.invalidImage }
        let values = try file.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true, let count = values.fileSize, count > 0 else { throw ExportError.invalidImage }
        guard count <= 120 * 1024 * 1024 else { throw ExportError.tooLarge }
        return try prepare(data: Data(contentsOf: file, options: .mappedIfSafe))
    }
    static func prepare(data: Data) throws -> PreparedImage {
        guard !data.isEmpty else { throw ExportError.invalidImage }
        guard data.count <= 120 * 1024 * 1024 else { throw ExportError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetCount(source) > 0,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
              width.doubleValue > 0, height.doubleValue > 0 else { throw ExportError.invalidImage }
        guard width.doubleValue * height.doubleValue <= 100_000_000 else { throw ExportError.tooLarge }
        guard CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCache: false] as CFDictionary) != nil,
              let container = CGImageSourceGetType(source) else { throw ExportError.invalidImage }
        let type = container as String
        let nativeTypes: [String: String] = [
            UTType.jpeg.identifier: "jpg", UTType.png.identifier: "png", UTType.gif.identifier: "gif",
            UTType.heic.identifier: "heic", UTType.heif.identifier: "heif"
        ]
        if let suffix = nativeTypes[type] {
            // Preserve pixels, orientation, animation and metadata, without re-compression.
            return PreparedImage(data: data, typeIdentifier: type, fileExtension: suffix)
        }
        // Other decodable image containers are exported as a full-resolution PNG.
        // Apply orientation to pixels rather than dropping its metadata accidentally.
        let maximum = max(width.intValue, height.intValue)
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximum,
            kCGImageSourceShouldCacheImmediately: false
        ] as CFDictionary), let encoded = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(encoded, UTType.png.identifier as CFString, 1, nil) else {
            throw ExportError.encodingFailed
        }
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: 1] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ExportError.encodingFailed }
        return PreparedImage(data: encoded as Data, typeIdentifier: UTType.png.identifier, fileExtension: "png")
    }
}
