import SwiftUI

struct MediaFailureView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            Image(
                systemName:
                    "exclamationmark.circle"
            )
            .font(.title2)
            .foregroundStyle(
                .secondary
            )

            Text(
                "Media unavailable"
            )
            .font(
                .subheadline.weight(
                    .medium
                )
            )

            Button(
                "Try Again",
                action: retry
            )
            .font(
                .subheadline.weight(
                    .semibold
                )
            )
            .foregroundStyle(
                AppVisualDesign.accent
            )
        }
        .frame(
            minWidth: 190,
            minHeight: 110
        )
        .padding(12)
        .background(
            Color.primary
                .opacity(0.045),
            in:
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
        )
    }
}
