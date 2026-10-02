import UIKit
import ImageIO

actor ChatImageCache {
    static let shared = ChatImageCache()
    private let images = NSCache<NSString, UIImage>()
    init() { images.totalCostLimit = 48 * 1024 * 1024; images.countLimit = 160 }
    func image(at url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        if let cached = images.object(forKey: key) { return cached }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1024,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { return nil }
        let result = UIImage(cgImage: cg)
        images.setObject(result, forKey: key, cost: cg.width * cg.height * 4)
        return result
    }
}
