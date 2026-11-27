import Foundation
import AVFoundation
import Combine

// Each observer belongs to the exact player that created it. The lease is also
// a fallback cleanup path when SwiftUI destroys a view without another update.
private final class VideoPlaybackLease {
    let player: AVPlayer
    var timeToken: Any?
    var endToken: NSObjectProtocol?
    private var invalidated = false
    init(player: AVPlayer) { self.player = player }
    func invalidate() {
        guard !invalidated else { return }
        invalidated = true
        player.pause()
        if let timeToken { player.removeTimeObserver(timeToken); self.timeToken = nil }
        if let endToken { NotificationCenter.default.removeObserver(endToken); self.endToken = nil }
        player.currentItem?.cancelPendingSeeks()
        player.currentItem?.asset.cancelLoading()
        player.replaceCurrentItem(with: nil)
    }
    deinit { invalidate() }
}

@MainActor
final class ManagedVideoPlayback: ObservableObject {
    @Published private(set) var player: AVPlayer?
    @Published private(set) var position = 0.0
    @Published private(set) var duration = 0.0
    @Published private(set) var playing = false
    @Published private(set) var speed: Float = 1
    private var lease: VideoPlaybackLease?
    private var generation = UUID()
    private var url: URL?
    private var scrubbing = false
    private var resumeAfterScrub = false

    func prepare(url: URL, autoplay: Bool = true) {
        if self.url == url, player != nil { return }
        stop()
        self.url = url
        let token = generation
        let media = AVPlayer(url: url)
        let owned = VideoPlaybackLease(player: media)
        lease = owned
        player = media
        owned.timeToken = media.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            let seconds = time.seconds
            Task { @MainActor [weak self] in
                guard let self, self.generation == token, self.player != nil else { return }
                if !self.scrubbing, seconds.isFinite { self.position = max(0, seconds) }
                if let value = self.player?.currentItem?.duration.seconds, value.isFinite {
                    self.duration = max(0, value)
                }
            }
        }
        owned.endToken = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: media.currentItem, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                self.playing = false
            }
        }
        if autoplay { play() }
    }
    func play() {
        guard let player else { return }
        if duration > 0, position >= duration - 0.05 { player.seek(to: .zero); position = 0 }
        playing = true
        player.playImmediately(atRate: speed)
    }
    func pause() { playing = false; player?.pause() }
    func toggle() { if playing { pause() } else { play() } }
    func setSpeed(_ value: Float) {
        guard value.isFinite, value >= 0.5, value <= 2 else { return }
        speed = value
        if playing { player?.playImmediately(atRate: speed) }
    }
    func setScrubPosition(_ value: Double) {
        guard value.isFinite else { return }
        position = min(max(0, value), max(0, duration))
    }
    func scrubEditing(_ editing: Bool) {
        if editing {
            scrubbing = true
            resumeAfterScrub = playing
            player?.pause()
        } else {
            scrubbing = false
            player?.cancelPendingPrerolls()
            player?.currentItem?.cancelPendingSeeks()
            player?.seek(to: CMTime(seconds: position, preferredTimescale: 600),
                         toleranceBefore: CMTime(seconds: 0.1, preferredTimescale: 600),
                         toleranceAfter: CMTime(seconds: 0.1, preferredTimescale: 600))
            if resumeAfterScrub { player?.playImmediately(atRate: speed) }
        }
    }
    func stop() {
        generation = UUID() // Ignore already-queued observer callbacks after closing.
        lease?.invalidate()
        lease = nil
        player = nil
        url = nil
        playing = false
        position = 0
        duration = 0
        scrubbing = false
        resumeAfterScrub = false
    }
    deinit { lease?.invalidate() }
}
