import SwiftUI

struct MediaUnavailableView: View {
    let retry:
        (() -> Void)?

    var body: some View {
        VStack(spacing: 7) {
            Image(
                systemName:
                    "photo.badge.exclamationmark"
            )
            .font(
                .title3
            )

            Text(
                "Media unavailable"
            )
            .font(
                .caption.bold()
            )

            if let retry {
                Button(
                    "Retry",
                    action:
                        retry
                )
                .font(.caption)
            }
        }
        .foregroundStyle(
            .secondary
        )
        .padding(12)
    }
}
