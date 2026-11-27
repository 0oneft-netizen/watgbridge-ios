import SwiftUI
import AVFoundation
import UIKit

// One small still image per file; no playback objects or periodic timers in
// scrolling message rows. Decoding runs on one utility queue, never the UI thread.
private actor VideoPosterCache {
    static let shared = VideoPosterCache()
    private let images = NSCache<NSURL, UIImage>()
    private var pending: [URL: Task<UIImage?, Never>] = [:]
    private let queue = DispatchQueue(label: "ultra.video.poster", qos: .utility)
    init() { images.countLimit = 60; images.totalCostLimit = 12 * 1024 * 1024 }
    func image(at url: URL) async -> UIImage? {
        guard url.isFileURL else { return nil }
        if let image = images.object(forKey: url as NSURL) { return image }
        if let task = pending[url] { return await task.value }
        let decoderQueue = queue
        let task = Task<UIImage?, Never> {
          await withCheckedContinuation { continuation in
            decoderQueue.async {
                autoreleasepool {
                    let asset = AVURLAsset(url: url)
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.maximumSize = CGSize(width: 480, height: 480)
                    let cg = try? generator.copyCGImage(at: .zero, actualTime: nil)
                    generator.cancelAllCGImageGeneration()
                    asset.cancelLoading()
                    continuation.resume(returning: cg.map { UIImage(cgImage: $0) })
                }
            }
        }
        }
        pending[url] = task
        let image = await task.value
        pending[url] = nil
        if let image { images.setObject(image, forKey: url as NSURL, cost: Int(image.size.width * image.size.height * 4)) }
        return image
    }
}
struct ChatVideoPoster: View {
    let url: URL
    @State private var image: UIImage?
    var body: some View {
        ZStack {
            Color.black
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: "video.fill").foregroundStyle(.white.opacity(0.6)) }
        }
        .clipped()
        .task(id: url) {
            image = nil
            let result = await VideoPosterCache.shared.image(at: url)
            guard !Task.isCancelled else { return }
            image = result
        }
    }
}
