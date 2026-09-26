import SwiftUI

struct InboxSessionChip: View {
    let accountID:
        String?

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var name:
        String {
        sessions.name(
            for:
                accountID
                ?? "default"
        )
    }

    var body: some View {
        if !name.isEmpty {
            Text(name)
                .font(
                    .caption2.weight(
                        .semibold
                    )
                )
                .lineLimit(1)
                .foregroundStyle(
                    .secondary
                )
        }
    }
}
