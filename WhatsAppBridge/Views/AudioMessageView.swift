import SwiftUI
import AVFoundation

struct AudioMessageView: View {
    let url: URL
    let isVoice: Bool

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                togglePlayback()
            } label: {
                Image(
                    systemName:
                        isPlaying
                        ? "pause.fill"
                        : "play.fill"
                )
                .font(.title3)
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    Circle()
                        .fill(
                            Color.secondary
                                .opacity(0.15)
                        )
                )
            }

            Image(
                systemName:
                    isVoice
                    ? "waveform"
                    : "music.note"
            )
            .font(.title3)

            Text(
                isVoice
                ? "Voice message"
                : "Audio"
            )
            .font(.subheadline)

            Spacer()
        }
        .frame(
            minWidth: 190
        )
        .onDisappear {
            player?.pause()
        }
    }

    private func togglePlayback() {
        if player == nil {
            player = AVPlayer(
                url: url
            )
        }

        guard let player else {
            return
        }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }

        isPlaying.toggle()
    }
}
