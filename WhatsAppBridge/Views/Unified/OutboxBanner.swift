import SwiftUI

struct OutboxBanner: View {
    let count: Int
    let retry: () -> Void

    var body: some View {
        if count > 0 {
            Button(action: retry) {
                HStack(spacing: 9) {
                    Image(
                        systemName:
                            "arrow.clockwise.circle.fill"
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 2
                    ) {
                        Text(
                            count == 1
                            ? "1 message waiting"
                            : "\(count) messages waiting"
                        )
                        .font(
                            .caption.bold()
                        )

                        Text(
                            "Tap to retry"
                        )
                        .font(.caption2)
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(.caption)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .background(
                .regularMaterial
            )
        }
    }
}
