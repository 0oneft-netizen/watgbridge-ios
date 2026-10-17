import SwiftUI
import AVFoundation

struct UltraVoiceDraft: Identifiable { let id = UUID(); let url: URL }

@MainActor final class UltraVoiceReviewPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var playing = false
    private var player: AVAudioPlayer?
    private let lease = UUID()
    private var ownsLease = false
    func play(_ url: URL, from: Double, to: Double) throws {
        stop()
        guard UltraAudioLease.acquire(lease) else { throw UltraVoiceError.busy }
        ownsLease = true
        do {
            let session = AVAudioSession.sharedInstance(); try session.setCategory(.playback, mode: .spokenAudio); try session.setActive(true)
            let value = try AVAudioPlayer(contentsOf: url); value.delegate = self; value.currentTime = from; value.prepareToPlay()
            guard value.play() else { throw URLError(.cannotDecodeContentData) }
            player = value; playing = true
            Task { [weak self, weak value] in
                while let self, let value, self.playing, self.player === value {
                    if value.currentTime >= to { self.stop(); return }
                    do { try await Task.sleep(nanoseconds: 50_000_000) } catch { return }
                }
            }
        } catch { stop(); throw error }
    }
    func stop() {
        player?.stop(); player = nil; playing = false
        if ownsLease { _ = UltraAudioLease.release(lease); ownsLease = false; try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
    }
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { Task { @MainActor [weak self] in self?.stop() } }
}

@MainActor struct UltraVoiceReviewView: View {
    let draft: UltraVoiceDraft
    let onSend: (URL) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var player = UltraVoiceReviewPlayer()
    @State private var duration = 0.0
    @State private var start = 0.0
    @State private var end = 0.0
    @State private var busy = false
    @State private var error: String?
    @State private var scope = UserWorkspace.id
    var body: some View {
        NavigationStack {
            Form {
                Section("בדיקה לפני שליחה") {
                    Text("ההקלטה עדיין לא נשלחה. אפשר להאזין ולחתוך את ההתחלה והסוף.")
                    if duration > 0 {
                        Text("קטע נבחר: \(Int(max(0, end-start))) שניות")
                        Text("התחלה: \(String(format: "%.1f", start)) שנ׳")
                        Slider(value: $start, in: 0...max(0.01, duration-0.1)).onChange(of: start) { _, _ in player.stop(); if end < start+0.1 { end = min(duration,start+0.1) } }
                        Text("סיום: \(String(format: "%.1f", end)) שנ׳")
                        Slider(value: $end, in: 0.1...max(0.1,duration)).onChange(of: end) { _, _ in player.stop(); if start > end-0.1 { start = max(0,end-0.1) } }
                        Button(player.playing ? "עצור האזנה" : "האזן לקטע שנבחר") {
                            if player.playing { player.stop() } else { do { try player.play(draft.url, from: start, to: end) } catch { self.error = error.localizedDescription } }
                        }
                        Button("אפס חיתוך") { player.stop(); start = 0; end = duration }
                    }
                }
                Button("שלח הקלטה לצ׳אט") { Task { await send() } }.disabled(busy || duration <= 0 || end-start < 0.1)
                if busy { ProgressView("מכין ושומר לתור השליחה…") }
                if let error { Text(error).foregroundStyle(.secondary) }
            }.disabled(busy).navigationTitle("עריכת הקלטה")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("ביטול") { dismiss() }.disabled(busy) } }
            .interactiveDismissDisabled(busy)
            .task {
                do { let value = try await AVURLAsset(url: draft.url).load(.duration).seconds; guard value.isFinite, value > 0.1 else { throw URLError(.cannotDecodeContentData) }; duration = value; end = value }
                catch { self.error = "לא ניתן לפתוח את ההקלטה." }
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active { player.stop() } }
            .onDisappear { player.stop(); try? FileManager.default.removeItem(at: draft.url) }
        }
    }
    private func send() async {
        guard !busy, UserWorkspace.id == scope else { return }; busy = true; defer { busy = false }; player.stop()
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("voice-trim-\(UUID().uuidString).m4a")
        defer { try? FileManager.default.removeItem(at: output) }
        do {
            guard let export = AVAssetExportSession(asset: AVURLAsset(url: draft.url), presetName: AVAssetExportPresetAppleM4A) else { throw URLError(.cannotDecodeContentData) }
            export.outputURL = output; export.outputFileType = .m4a
            export.timeRange = CMTimeRange(start: CMTime(seconds: start, preferredTimescale: 600), duration: CMTime(seconds: end-start, preferredTimescale: 600))
            await withCheckedContinuation { (continuation: CheckedContinuation<Void,Never>) in export.exportAsynchronously { continuation.resume() } }
            guard export.status == .completed, UserWorkspace.id == scope else { throw URLError(.cannotDecodeContentData) }
            if await onSend(output) { dismiss() } else { error = "לא ניתן לשמור לתור השליחה. ההקלטה המקורית נשארה כאן, ואפשר לנסות שוב." }
        } catch { self.error = "לא ניתן להכין את הקטע. ההקלטה המקורית עדיין זמינה כאן." }
    }
}
