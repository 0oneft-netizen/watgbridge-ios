import SwiftUI
import AVFoundation
import UIKit
import Combine

struct WhatsAppRoundVideoNote: View {
    let url: URL
    let onExpand: () -> Void
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var progress: CGFloat = 0
    @Environment(\.scenePhase) private var scenePhase
    private let clock = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            Button(action: togglePlayback) {
                ZStack {
                    Circle().fill(Color.black)
                    if let player {
                        WhatsAppVideoSurface(player: player)
                    }
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(.black.opacity(0.35), in: Circle())
                }
                .frame(width: 210, height: 210)
                .clipShape(Circle())
                .overlay(Circle().stroke(WhatsAppVisualDesign.border, lineWidth: 2))
                .overlay {
                    Circle().trim(from: 0, to: progress)
                        .stroke(WhatsAppVisualDesign.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pause video message" : "Play video message")
            .accessibilityAddTraits(.startsMediaSession)

            Button {
                player?.pause()
                isPlaying = false
                onExpand()
            } label: {
                Label("Open video", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption)
                    .foregroundStyle(WhatsAppVisualDesign.accent)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            if player == nil { player = AVPlayer(url: url) }
        }
        .onChange(of: url) {
            player?.pause()
            player = AVPlayer(url: url)
            isPlaying = false
            progress = 0
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
        }
        .onChange(of: scenePhase) {
            if scenePhase != .active {
                player?.pause()
                isPlaying = false
            }
        }
        .onReceive(clock) { _ in
            guard let player, let item = player.currentItem else { return }
            let duration = item.duration.seconds
            let position = player.currentTime().seconds
            if duration.isFinite && duration > 0 && position.isFinite {
                progress = CGFloat(min(1, max(0, position / duration)))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard let item = notification.object as? AVPlayerItem,
                  item === player?.currentItem else { return }
            isPlaying = false
            player?.seek(to: .zero)
            progress = 0
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}

private struct WhatsAppVideoSurface: UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(context: Context) -> WhatsAppPlayerView {
        let view = WhatsAppPlayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }
    func updateUIView(_ view: WhatsAppPlayerView, context: Context) {
        view.playerLayer.player = player
    }
    static func dismantleUIView(_ view: WhatsAppPlayerView, coordinator: ()) {
        view.playerLayer.player = nil
    }
}

private final class WhatsAppPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
