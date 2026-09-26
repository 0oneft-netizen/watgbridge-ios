import SwiftUI

struct SessionConnectionChip: View {
    let status:
        String

    var body: some View {
        Label(
            SessionStatusPresentation
                .title(
                    status
                ),
            systemImage:
                SessionStatusPresentation
                    .icon(
                        status
                    )
        )
        .font(
            .caption.bold()
        )
        .foregroundStyle(
            foreground
        )
    }

    private var foreground:
        Color {

        switch status
            .lowercased() {

        case "connected":
            return .green

        case "disconnected":
            return .red

        case "reconnect_required":
            return .orange

        default:
            return .secondary
        }
    }
}
