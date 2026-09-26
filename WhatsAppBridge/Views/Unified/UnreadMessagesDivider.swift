import SwiftUI

struct UnreadMessagesDivider: View {
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(
                    Color.secondary
                        .opacity(0.25)
                )

            Text(
                count > 0
                ? "\(count) unread"
                : "Unread messages"
            )
            .font(
                .caption.bold()
            )
            .foregroundStyle(
                .secondary
            )
            .fixedSize()

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(
                    Color.secondary
                        .opacity(0.25)
                )
        }
        .padding(
            .vertical,
            8
        )
    }
}
