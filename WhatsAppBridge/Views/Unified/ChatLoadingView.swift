import SwiftUI

struct ChatLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            ProgressView()

            Text(
                "Loading messages…"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}
