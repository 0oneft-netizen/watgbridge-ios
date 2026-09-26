import SwiftUI

struct ChatErrorBanner: View {
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .lineLimit(2)

            Spacer()

            if let retry {
                Button("Retry") {
                    retry()
                }
                .font(
                    .caption.bold()
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            .regularMaterial
        )
    }
}
