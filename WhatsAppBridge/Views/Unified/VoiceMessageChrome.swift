import SwiftUI

struct VoiceMessageChrome: View {
    let isPlaying: Bool
    let progress: Double
    let durationText: String
    let action: () -> Void

    private var safeProgress: Double {
        min(
            max(progress, 0),
            1
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(
                action: action
            ) {
                Image(
                    systemName:
                        isPlaying
                        ? "pause.fill"
                        : "play.fill"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    .white
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    AppVisualDesign.accent,
                    in: Circle()
                )
            }
            .buttonStyle(.plain)

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                GeometryReader {
                    proxy in

                    ZStack(
                        alignment: .leading
                    ) {
                        Capsule()
                            .fill(
                                Color.secondary
                                    .opacity(0.22)
                            )
                            .frame(
                                height: 3
                            )

                        Capsule()
                            .fill(
                                AppVisualDesign
                                    .accent
                            )
                            .frame(
                                width:
                                    proxy.size.width
                                    * safeProgress,
                                height: 3
                            )
                    }
                    .frame(
                        maxHeight:
                            .infinity
                    )
                }
                .frame(height: 8)

                HStack {
                    Image(
                        systemName:
                            "waveform"
                    )

                    Spacer()

                    Text(durationText)
                }
                .font(
                    .system(
                        size: 10,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .frame(
            minWidth: 205
        )
        .padding(
            .vertical,
            3
        )
    }
}
