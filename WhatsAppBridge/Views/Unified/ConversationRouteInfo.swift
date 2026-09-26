import SwiftUI

struct ConversationRouteInfo: View {
    let conversation:
        Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var sessionName:
        String {
        sessions.name(
            for:
                conversation
                    .accountID
                ?? "default"
        )
    }

    var body: some View {
        if !sessionName.isEmpty {
            HStack(spacing: 6) {
                Image(
                    systemName:
                        "arrow.triangle.branch"
                )
                .font(.caption2)

                Text(
                    "Via "
                    + sessionName
                )
                .font(
                    .caption
                )
            }
            .foregroundStyle(
                .secondary
            )
        }
    }
}
