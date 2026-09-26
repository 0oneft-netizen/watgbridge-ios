import SwiftUI

struct FailedSendBanner: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        if count > 0 {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(
                        systemName:
                            "exclamationmark.circle.fill"
                    )

                    Text(
                        count == 1
                        ? "1 message failed to send"
                        : "\(count) messages failed to send"
                    )

                    Spacer()

                    Text("Retry")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.red)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    .ultraThinMaterial
                )
            }
            .buttonStyle(.plain)
        }
    }
}
