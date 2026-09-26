import SwiftUI

struct CustomerLabelChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(
                .caption2.weight(
                    .semibold
                )
            )
            .lineLimit(1)
            .padding(
                .horizontal,
                7
            )
            .padding(
                .vertical,
                3
            )
            .background(
                Color.green
                    .opacity(0.12),
                in: Capsule()
            )
    }
}
