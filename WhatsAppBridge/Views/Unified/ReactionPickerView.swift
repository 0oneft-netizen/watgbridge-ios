import SwiftUI

struct ReactionPickerView: View {
    let onSelect: (String) -> Void

    private let reactions = [
        "👍",
        "❤️",
        "😂",
        "😮",
        "😢",
        "🙏"
    ]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(
                reactions,
                id: \.self
            ) { reaction in
                Button {
                    AppHaptics.light()

                    onSelect(reaction)
                } label: {
                    Text(reaction)
                        .font(.system(size: 25))
                        .frame(
                            width: 39,
                            height: 39
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(
                    Color.secondary.opacity(0.12),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: .black.opacity(0.12),
            radius: 10,
            y: 4
        )
    }
}
