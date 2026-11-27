import SwiftUI
import AVFoundation
import UIKit

@MainActor
struct WhatsAppRoundVideoNote: View {
    let url: URL
    let onExpand: () -> Void
    @StateObject private var playback = ManagedVideoPlayback()
    @Environment(\.scenePhase) private var scenePhase
    private var progress: CGFloat {
        playback.duration > 0 ? CGFloat(min(1, max(0, playback.position / playback.duration))) : 0
    }
    var body: some View {
        VStack(spacing: 8) {
            Button {
                if playback.player == nil { playback.prepare(url: url) }
                else { playback.toggle() }
            } label: {
                ZStack {
                    Circle().fill(Color.black)
                    if let player = playback.player { WhatsAppVideoSurface(player: player) }
                    Image(systemName: playback.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .semibold)).foregroundStyle(.white)
                        .padding(16).background(.black.opacity(0.35), in: Circle())
                }
                .frame(width: 210, height: 210).clipShape(Circle())
                .overlay(Circle().stroke(WhatsAppVisualDesign.border, lineWidth: 2))
                .overlay {
                    Circle().trim(from: 0, to: progress)
                        .stroke(WhatsAppVisualDesign.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playback.playing ? "Pause video message" : "Play video message")
            .accessibilityAddTraits(.startsMediaSession)
            Button { playback.stop(); onExpand() } label: {
                Label("Open video", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption).foregroundStyle(WhatsAppVisualDesign.accent)
            }.buttonStyle(.plain)
        }
        .onChange(of: url) { _, _ in playback.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { playback.stop() } }
        .onDisappear { playback.stop() }
    }
}
@MainActor
private struct WhatsAppVideoSurface: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> WhatsAppVideoUIView {
        let view = WhatsAppVideoUIView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }
    func updateUIView(_ uiView: WhatsAppVideoUIView, context: Context) {
        if uiView.playerLayer.player !== player { uiView.playerLayer.player = player }
    }
    static func dismantleUIView(_ uiView: WhatsAppVideoUIView, coordinator: ()) {
        uiView.playerLayer.player = nil
    }
}
private final class WhatsAppVideoUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
