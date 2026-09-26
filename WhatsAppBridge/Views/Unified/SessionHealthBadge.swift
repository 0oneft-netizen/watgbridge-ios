import SwiftUI

struct SessionHealthBadge: View {
    let level:
        SessionHealthLevel

    var body: some View {
        Label(
            level.title,
            systemImage:
                level.systemImage
        )
        .font(
            .caption.weight(
                .semibold
            )
        )
        .foregroundStyle(
            foreground
        )
    }

    private var foreground:
        Color {
        switch level {
        case .healthy:
            return .green
        case .attention:
            return .orange
        case .offline:
            return .red
        case .unknown:
            return .secondary
        }
    }
}
