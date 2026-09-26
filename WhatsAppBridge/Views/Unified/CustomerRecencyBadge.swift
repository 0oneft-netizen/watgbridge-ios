import SwiftUI

struct CustomerRecencyBadge: View {
    let timestamp: Int64

    var body: some View {
        Text(
            ConversationFreshness
                .ageText(
                    timestamp:
                        timestamp
                )
        )
        .font(
            .caption2
                .monospacedDigit()
        )
        .foregroundStyle(
            foreground
        )
    }

    private var foreground:
        Color {
        switch CustomerRecency
            .level(
                timestamp:
                    timestamp
            ) {

        case .recent:
            return .secondary

        case .aging:
            return .orange

        case .stale:
            return .secondary
        }
    }
}
