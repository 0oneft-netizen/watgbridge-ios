import SwiftUI

struct ChatConnectionBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 7) {
            ProgressView()
                .controlSize(.mini)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
    }
}
