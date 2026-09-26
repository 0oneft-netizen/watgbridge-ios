import SwiftUI

struct JumpToLatestButton: View {
    let unreadCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(
                    systemName:
                        "chevron.down"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .frame(
                    width: 42,
                    height: 42
                )
                .background(
                    .regularMaterial,
                    in: Circle()
                )
                .shadow(radius: 3)

                if unreadCount > 0 {
                    Text(
                        unreadCount > 99
                            ? "99+"
                            : "\(unreadCount)"
                    )
                    .font(
                        .system(
                            size: 9,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(
                        Color.green,
                        in: Capsule()
                    )
                    .offset(
                        x: 5,
                        y: -5
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }
}
