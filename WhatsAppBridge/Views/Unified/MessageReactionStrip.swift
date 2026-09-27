import SwiftUI

struct MessageReactionStrip: View {
    let react: (String) -> Void

    private let reactions = [
        "❤️",
        "👍",
        "😂",
        "😮",
        "😢",
        "🙏"
    ]

    var body: some View {
        HStack(spacing: 11) {
            ForEach(
                reactions,
                id: \.self
            ) { emoji in
                Button {
                    react(emoji)
                } label: {
                    Text(emoji)
                        .font(
                            .system(size: 22)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
    }
}
