import SwiftUI

struct EmptyConversationView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(
                systemName:
                    "message.fill"
            )
            .font(
                .system(size: 32)
            )
            .foregroundStyle(
                .secondary
            )

            Text(
                "No messages yet"
            )
            .font(
                .headline
            )

            Text(
                "Send a message to start the conversation."
            )
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
    }
}
