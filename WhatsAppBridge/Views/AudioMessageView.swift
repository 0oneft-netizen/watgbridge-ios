import SwiftUI
import AVFoundation

struct AudioMessageView: View {
    let url: URL
    let isVoice: Bool

    @State private var player: AVPlayer?
    @State private var observer: Any?
    @State private var isPlaying = false
    @State private var current: Double = 0
    @State private var duration: Double = 0
    @State private var rate: Float = 1

    var body: some View {
        HStack(spacing: 10) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.secondary.opacity(0.14)))
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { current },
                        set: { seek(to: $0) }
                    ),
                    in: 0...max(duration, 0.1)
                )

                HStack {
                    Text(time(current))
                    Spacer()
                    Text(time(duration))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            }
            .frame(minWidth: 130)

            if isVoice {
                Button(action: cycleRate) {
                    Text(rateLabel)
                        .font(.caption.bold())
                        .frame(minWidth: 32)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 220)
        .task(id: url) {
            preparePlayer()
        }
        .onDisappear {
            cleanup()
        }
    }

    private var rateLabel: String {
        rate == 1 ? "1×" : rate == 1.5 ? "1.5×" : "2×"
    }

    private func preparePlayer() {
        cleanup()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)

        player = newPlayer

        Task {
            if let value = try? await item.asset.load(.duration) {
                let seconds = CMTimeGetSeconds(value)

                await MainActor.run {
                    if seconds.isFinite {
                        duration = max(0, seconds)
                    }
                }
            }
        }

        observer = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { value in
            let seconds = CMTimeGetSeconds(value)

            if seconds.isFinite {
                current = max(0, seconds)
            }

            if duration > 0 && current >= duration - 0.1 {
                isPlaying = false
            }
        }
    }

    private func togglePlayback() {
        guard let player else {
            preparePlayer()
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if duration > 0 && current >= duration - 0.1 {
                player.seek(to: .zero)
                current = 0
            }

            player.playImmediately(atRate: rate)
            isPlaying = true
        }
    }

    private func seek(to seconds: Double) {
        current = seconds

        player?.seek(
            to: CMTime(
                seconds: seconds,
                preferredTimescale: 600
            ),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    private func cycleRate() {
        if rate == 1 {
            rate = 1.5
        } else if rate == 1.5 {
            rate = 2
        } else {
            rate = 1
        }

        if isPlaying {
            player?.rate = rate
        }
    }

    private func time(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }

        let total = max(0, Int(seconds.rounded()))
        return String(
            format: "%d:%02d",
            total / 60,
            total % 60
        )
    }

    private func cleanup() {
        if let observer, let player {
            player.removeTimeObserver(observer)
        }

        observer = nil
        player?.pause()
        player = nil
        isPlaying = false
    }
}
