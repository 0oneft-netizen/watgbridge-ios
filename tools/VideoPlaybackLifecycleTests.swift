import Foundation
import AVFoundation

@main struct VideoLifecycleTests {
    @MainActor static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        // Local fixture files only; never reach a user account or media server.
        func fixture(_ name: String) throws -> URL {
            let url = root.appendingPathComponent(name + ".wav")
            let format = AVAudioFormat(standardFormatWithSampleRate: 16000, channels: 1)!
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1600)!
            buffer.frameLength = 1600
            for index in 0..<1600 { buffer.floatChannelData![0][index] = 0 }
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
            return url
        }
        let a = try fixture("first"), b = try fixture("second")
        let playback = ManagedVideoPlayback()
        for _ in 0..<50 {
            playback.prepare(url: a, autoplay: false)
            guard let first = playback.player else { fatalError("player not created") }
            playback.prepare(url: a, autoplay: false)
            precondition(playback.player === first, "view updates recreated the player")
            playback.prepare(url: b, autoplay: false)
            precondition(first.currentItem == nil, "replaced player retained its media")
            guard let second = playback.player else { fatalError("second player missing") }
            playback.setSpeed(.nan)
            precondition(playback.speed == 1)
            playback.stop()
            precondition(playback.player == nil && second.currentItem == nil)
            precondition(playback.position == 0 && playback.duration == 0 && !playback.playing)
            playback.stop() // Multiple close/dismantle events are safe.
        }
        weak var released: ManagedVideoPlayback?
        autoreleasepool {
            let temporary = ManagedVideoPlayback()
            temporary.prepare(url: a, autoplay: false)
            released = temporary
        }
        precondition(released == nil, "observer retained the playback owner")
        print("PASS: 50 open/replace/close cycles, stable player identity, item release, repeated close and owner deallocation")
    }
}
