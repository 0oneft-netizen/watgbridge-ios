import SwiftUI

struct EmptyConversationState: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(
                systemName:
                    "message.fill"
            )
            .font(
                .system(size: 36)
            )
            .foregroundStyle(
                AppVisualDesign.accent
            )

            Text(title)
                .font(
                    .headline
                )

            Text(subtitle)
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )
        }
        .padding(30)
        .frame(
            maxWidth: 360
        )
    }
}
