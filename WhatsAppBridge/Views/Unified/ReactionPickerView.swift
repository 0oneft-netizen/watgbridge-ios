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
        HStack(spacing: 14) {
            ForEach(
                reactions,
                id: \.self
            ) { reaction in
                Button {
                    onSelect(
                        reaction
                    )
                } label: {
                    Text(reaction)
                        .font(
                            .system(
                                size: 25
                            )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            .regularMaterial,
            in: Capsule()
        )
    }
}
