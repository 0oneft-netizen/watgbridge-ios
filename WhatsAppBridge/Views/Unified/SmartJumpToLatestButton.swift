import SwiftUI

struct SmartJumpToLatestButton: View {
    let unseen: Int
    let action: () -> Void

    var body: some View {
        Button(
            action: action
        ) {
            HStack(spacing: 5) {
                if unseen > 0 {
                    Text(
                        unseen > 99
                        ? "99+"
                        : "\(unseen)"
                    )
                    .font(
                        .caption.bold()
                    )
                }

                Image(
                    systemName:
                        "chevron.down"
                )
            }
            .frame(
                minWidth: 38,
                minHeight: 38
            )
            .padding(
                .horizontal,
                unseen > 0
                ? 5
                : 0
            )
            .background(
                .regularMaterial,
                in: Capsule()
            )
            .shadow(
                radius: 3,
                y: 1
            )
        }
        .buttonStyle(.plain)
    }
}
