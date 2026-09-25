import SwiftUI

struct SessionRouteBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "iphone")

            Text(name)
                .lineLimit(1)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            .thinMaterial,
            in: Capsule()
        )
    }
}
