import AVFoundation
import PhotosUI
import SwiftUI
import CoreImage.CIFilterBuiltins
import UniformTypeIdentifiers

struct UltraMediaDraft: Identifiable {
    let id = UUID()
    let original: URL
    var current: URL
    let isVideo: Bool
    let originalName: String
    let originalMime: String
    var caption = ""
    var cover: Data?
    var edited = false
}
enum UltraMediaQuality: String, CaseIterable, Identifiable {
    case economy, high, original
    var id: String { rawValue }
    var title: String { switch self { case .economy: return "חסכוני"; case .high: return "איכות גבוהה"; case .original: return "מקורי" } }
}
struct UltraPreparedMedia {
    let data: Data
    let type: String
    let mime: String
    let filename: String
    let caption: String
    let thumbnail: Data?
}
enum UltraMediaEditing {
    static func temporary(_ ext: String) -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("ultra-" + UUID().uuidString).appendingPathExtension(ext) }
    static func load(_ items: [PhotosPickerItem]) async throws -> [UltraMediaDraft] {
        var result: [UltraMediaDraft] = []
        var totalBytes = 0
        do {
            for item in items.prefix(20) {
                try Task.checkCancellation()
                let video = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
                guard let data = try await item.loadTransferable(type: Data.self), data.count <= 100 * 1024 * 1024 else { throw URLError(.dataLengthExceedsMaximum) }
                totalBytes += data.count
                guard totalBytes <= 300 * 1024 * 1024 else { throw URLError(.dataLengthExceedsMaximum) }
                let type = item.supportedContentTypes.first ?? (video ? .movie : .jpeg)
                let ext = type.preferredFilenameExtension ?? (video ? "mov" : "jpg")
                let url = temporary(ext)
                try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
                result.append(.init(original: url, current: url, isVideo: video, originalName: "media.\(ext)", originalMime: type.preferredMIMEType ?? "application/octet-stream"))
            }
            try Task.checkCancellation()
            return result
        } catch { for file in result { try? FileManager.default.removeItem(at: file.original) }; throw error }
    }
    static func prepare(_ draft: UltraMediaDraft, quality: UltraMediaQuality) async throws -> UltraPreparedMedia {
        try await Task.detached(priority: .userInitiated) {
            if draft.isVideo {
                let url: URL
                if quality != .original {
                    url = try await exportVideo(draft.current, start: 0, end: nil, mute: false, turns: 0, quality: quality)
                } else { url = draft.current }
                defer { if url != draft.current { try? FileManager.default.removeItem(at: url) } }
                let data = try Data(contentsOf: url)
                guard data.count <= 100 * 1024 * 1024 else { throw URLError(.dataLengthExceedsMaximum) }
                return UltraPreparedMedia(data: data, type: "video", mime: url.pathExtension.lowercased() == "mov" ? "video/quicktime" : "video/mp4", filename: "video." + url.pathExtension, caption: draft.caption, thumbnail: draft.cover)
            }
            if quality == .original && !draft.edited {
                return UltraPreparedMedia(data: try Data(contentsOf: draft.original), type: "document", mime: draft.originalMime, filename: draft.originalName, caption: draft.caption, thumbnail: nil)
            }
            guard let image = UIImage(contentsOfFile: draft.current.path) else { throw URLError(.cannotDecodeContentData) }
            let limit: CGFloat = quality == .economy ? 1280 : (quality == .original ? 4096 : 2560)
            let scale = min(1, limit / max(image.size.width, image.size.height))
            let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
            let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
            let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            guard let data = resized.jpegData(compressionQuality: quality == .economy ? 0.72 : 0.92) else { throw URLError(.cannotCreateFile) }
            return UltraPreparedMedia(data: data, type: "image", mime: "image/jpeg", filename: "photo.jpg", caption: draft.caption, thumbnail: nil)
        }.value
    }
    static func exportVideo(_ url: URL, start: Double, end: Double?, mute: Bool, turns: Int, quality: UltraMediaQuality, cover: Data? = nil) async throws -> URL {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let total = duration.seconds
        guard total.isFinite, total > 0 else { throw URLError(.cannotDecodeContentData) }
        let begin = min(max(0, start), max(0, total - 0.1)), finish = min(max(begin + 0.1, end ?? total), total)
        let composition = AVMutableComposition()
        guard let video = try await asset.loadTracks(withMediaType: .video).first,
              let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { throw URLError(.cannotDecodeContentData) }
        let range = CMTimeRange(start: CMTime(seconds: begin, preferredTimescale: 600), duration: CMTime(seconds: finish - begin, preferredTimescale: 600))
        try track.insertTimeRange(range, of: video, at: .zero)
        if !mute, let source = try await asset.loadTracks(withMediaType: .audio).first, let audio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try audio.insertTimeRange(range, of: source, at: .zero)
        }
        let size = try await video.load(.naturalSize), preferred = try await video.load(.preferredTransform)
        let oriented = CGRect(origin: .zero, size: size).applying(preferred)
        let normalized = preferred.concatenating(CGAffineTransform(translationX: -oriented.minX, y: -oriented.minY))
        let rotated = normalized.concatenating(CGAffineTransform(rotationAngle: CGFloat(turns % 4) * .pi / 2))
        let bounds = CGRect(origin: .zero, size: size).applying(rotated)
        let final = rotated.concatenating(CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
        let instruction = AVMutableVideoCompositionInstruction(); instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: track); layer.setTransform(final, at: .zero); instruction.layerInstructions = [layer]
        let visual = AVMutableVideoComposition(); visual.instructions = [instruction]; visual.frameDuration = CMTime(value: 1, timescale: 30)
        visual.renderSize = CGSize(width: max(2, ceil(bounds.width / 2) * 2), height: max(2, ceil(bounds.height / 2) * 2))
        if let cover, let image = UIImage(data: cover)?.cgImage {
            let parent = CALayer(), film = CALayer(), poster = CALayer()
            let frame = CGRect(origin: .zero, size: visual.renderSize)
            parent.frame = frame; film.frame = frame; poster.frame = frame
            poster.contents = image; poster.contentsGravity = .resizeAspect; poster.backgroundColor = UIColor.black.cgColor; poster.opacity = 0
            let fade = CABasicAnimation(keyPath: "opacity"); fade.fromValue = 1; fade.toValue = 0
            fade.beginTime = AVCoreAnimationBeginTimeAtZero; fade.duration = 0.12; fade.fillMode = .forwards; fade.isRemovedOnCompletion = false
            poster.add(fade, forKey: "cover"); parent.addSublayer(film); parent.addSublayer(poster)
            visual.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: film, in: parent)
        }
        let preset = quality == .economy ? AVAssetExportPreset640x480 : quality == .high ? AVAssetExportPreset1920x1080 : AVAssetExportPresetHighestQuality
        guard let exporter = AVAssetExportSession(asset: composition, presetName: preset) else { throw URLError(.cannotCreateFile) }
        let output = temporary("mp4"); exporter.outputURL = output; exporter.outputFileType = .mp4; exporter.videoComposition = visual; exporter.shouldOptimizeForNetworkUse = true
        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in exporter.exportAsynchronously { continuation.resume() } }
        } onCancel: { exporter.cancelExport() }
        guard exporter.status == .completed else { try? FileManager.default.removeItem(at: output); throw exporter.error ?? URLError(.cannotCreateFile) }
        return output
    }
    static func poster(_ url: URL, seconds: Double) async throws -> Data {
        try await Task.detached {
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url)); generator.appliesPreferredTrackTransform = true; generator.maximumSize = CGSize(width: 480, height: 480)
            let image = try generator.copyCGImage(at: CMTime(seconds: seconds, preferredTimescale: 600), actualTime: nil)
            guard let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.8) else { throw URLError(.cannotCreateFile) }
            return data
        }.value
    }
}
