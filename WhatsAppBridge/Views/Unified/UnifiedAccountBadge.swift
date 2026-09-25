import SwiftUI

struct UnifiedAccountBadge: View {
    let name: String
    let phone: String?
    let connected: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(
                    connected
                    ? ChatDesign.accent
                    : Color.secondary
                )
                .frame(width: 8, height: 8)

            VStack(
                alignment: .leading,
                spacing: 1
            ) {
                Text(name)
                    .font(
                        .caption.weight(
                            .semibold
                        )
                    )

                if let phone,
                   !phone.isEmpty {
                    Text(phone)
                        .font(.caption2)
                        .foregroundStyle(
                            .secondary
                        )
                }
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}
