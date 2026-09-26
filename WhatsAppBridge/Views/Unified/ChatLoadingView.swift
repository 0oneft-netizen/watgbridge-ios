import SwiftUI

struct ChatLoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            Spacer()

            ProgressView()
                .controlSize(.regular)

            Text("Loading messages…")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(
            ChatBackgroundView()
        )
    }
}
