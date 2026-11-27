import SwiftUI
import AVKit

// Explicit UIKit teardown detaches AVKit from a closed SwiftUI presentation.
@MainActor
struct ManagedVideoSurface: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let view = AVPlayerViewController()
        view.allowsPictureInPicturePlayback = false
        view.player = player
        return view
    }
    func updateUIViewController(_ view: AVPlayerViewController, context: Context) {
        if view.player !== player { view.player = player }
    }
    static func dismantleUIViewController(_ view: AVPlayerViewController, coordinator: ()) {
        view.player?.pause()
        view.player = nil
    }
}
