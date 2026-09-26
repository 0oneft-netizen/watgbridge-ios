import SwiftUI

struct OutboxBadge: View {
    @ObservedObject
    private var outbox =
        PersistentOutbox.shared

    var body: some View {
        if !outbox.items.isEmpty {
            Text(
                outbox.items.count > 99
                ? "99+"
                : "\(outbox.items.count)"
            )
            .font(
                .caption2.bold()
            )
            .padding(
                .horizontal,
                6
            )
            .padding(
                .vertical,
                2
            )
            .background(
                Color.orange
                    .opacity(0.18),
                in:
                    Capsule()
            )
        }
    }
}
