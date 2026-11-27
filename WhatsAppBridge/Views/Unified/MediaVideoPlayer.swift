import SwiftUI
import AVKit

@MainActor
struct MediaVideoPlayer: View {
    let url: URL
    var autoplay = true
    @StateObject private var playback = ManagedVideoPlayback()
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if let player = playback.player { ManagedVideoSurface(player: player) }
            else { ProgressView().tint(.white) }
        }
        .task(id: url) { if scenePhase == .active { playback.prepare(url: url, autoplay: autoplay) } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { playback.prepare(url: url, autoplay: autoplay) }
            else { playback.stop() }
        }
        .onDisappear { playback.stop() }
    }
}
