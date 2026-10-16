import SwiftUI

struct OutboxBadge: View {
    @ObservedObject
    private var outbox =
        PersistentOutbox.shared

    @ObservedObject private var ultraQueue = UltraSendQueue.shared
    private var total: Int { outbox.items.count + ultraQueue.items.filter { $0.state != "sent" }.count }

    var body: some View {
        if total > 0 {
            Text(
                total > 99
                ? "99+"
                : "\(total)"
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
