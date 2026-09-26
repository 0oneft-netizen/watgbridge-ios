import SwiftUI

struct MediaFailureView: View {
    let type: String
    let retry: () -> Void

    var body: some View {
        Button(
            action: retry
        ) {
            VStack(spacing: 7) {
                Image(
                    systemName:
                        icon
                )
                .font(.title2)

                Text(
                    "Media unavailable"
                )
                .font(
                    .caption.bold()
                )

                Text(
                    "Tap to retry"
                )
                .font(
                    .caption2
                )
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                minWidth: 140,
                minHeight: 90
            )
            .background(
                Color.secondary
                    .opacity(0.08),
                in:
                    RoundedRectangle(
                        cornerRadius: 10
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var icon:
        String {
        switch type {
        case "video":
            return "video.slash"
        case "audio",
             "voice":
            return "waveform.badge.exclamationmark"
        case "document":
            return "doc.badge.ellipsis"
        default:
            return "photo.badge.exclamationmark"
        }
    }
}
