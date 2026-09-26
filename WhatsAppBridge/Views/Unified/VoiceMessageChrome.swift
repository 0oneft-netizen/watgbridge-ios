import SwiftUI

struct VoiceMessageChrome: View {
    let isPlaying: Bool
    let progress: Double
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                Image(
                    systemName:
                        isPlaying
                        ? "pause.fill"
                        : "play.fill"
                )
                .font(.system(size: 15))
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    ChatDesign.accent,
                    in: Circle()
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            VStack(spacing: 4) {
                ProgressView(
                    value:
                        min(
                            1,
                            max(0, progress)
                        )
                )
                .tint(ChatDesign.accent)

                HStack {
                    Image(
                        systemName:
                            "waveform"
                    )
                    .font(.caption2)

                    Spacer()

                    Text("Voice message")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 205)
    }
}
