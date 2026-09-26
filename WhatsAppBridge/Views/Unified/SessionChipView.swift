import SwiftUI

struct SessionChipView: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ChatDesign.accent)
                .frame(
                    width: 5,
                    height: 5
                )

            Text(name)
                .lineLimit(1)
        }
        .font(
            .system(
                size: 10.5,
                weight: .medium
            )
        )
        .foregroundStyle(.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            ChatDesign.subtleFill,
            in: Capsule()
        )
    }
}
