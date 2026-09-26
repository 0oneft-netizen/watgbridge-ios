import SwiftUI

struct NewMessagesButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if count > 0 {
                    Text(
                        count > 99
                        ? "99+"
                        : "\(count)"
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
            .padding(.horizontal, 12)
            .frame(height: 36)
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
