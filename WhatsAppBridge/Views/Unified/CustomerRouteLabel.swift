import SwiftUI

struct CustomerRouteLabel: View {
    let conversation:
        Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    var body: some View {
        VStack(
            alignment:
                .leading,
            spacing: 2
        ) {
            Text(
                CustomerIdentityPresentation
                    .title(
                        conversation:
                            conversation
                    )
            )
            .font(
                .headline
            )

            Text(
                sessions.name(
                    for:
                        conversation
                            .accountID
                        ?? "default"
                )
            )
            .font(
                .caption
            )
            .foregroundStyle(
                .secondary
            )
        }
    }
}
