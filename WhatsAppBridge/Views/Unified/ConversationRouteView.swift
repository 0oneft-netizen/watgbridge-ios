import SwiftUI

struct ConversationRouteView: View {
    let accountID: String?

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var name: String {
        sessions.name(for: accountID)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(
                systemName:
                    "arrow.turn.down.right"
            )
            .font(.system(size: 9))

            Text(name)
                .lineLimit(1)
        }
        .font(
            .system(
                size: 11,
                weight: .medium
            )
        )
        .foregroundStyle(.secondary)
        .task {
            if sessions.sessions.isEmpty {
                await sessions.refresh()
            }
        }
    }
}
