import SwiftUI

struct MediaUnavailableView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(
                systemName:
                    "photo.badge.exclamationmark"
            )
            .font(.title2)

            Text(
                "Media unavailable"
            )
            .font(
                .subheadline.weight(
                    .medium
                )
            )
        }
        .foregroundStyle(
            .secondary
        )
        .frame(
            minWidth: 190,
            minHeight: 105
        )
        .padding(10)
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
