import SwiftUI

struct LoadEarlierMessagesButton: View {
    let remaining: Int
    let action: () -> Void

    var body: some View {
        if remaining > 0 {
            Button(
                action: action
            ) {
                HStack(spacing: 6) {
                    Image(
                        systemName:
                            "arrow.up.circle"
                    )

                    Text(
                        "Load earlier messages"
                    )

                    Text(
                        "(\(remaining))"
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
                .font(
                    .caption.bold()
                )
                .padding(
                    .horizontal,
                    12
                )
                .padding(
                    .vertical,
                    8
                )
                .background(
                    .regularMaterial,
                    in: Capsule()
                )
            }
            .buttonStyle(.plain)
        }
    }
}
