import SwiftUI

struct SessionsHeaderView: View {
    let sessions: [SessionIdentity]

    private var connectedCount: Int {
        sessions.filter(\.isConnected).count
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 7
        ) {
            HStack {
                Image(
                    systemName:
                        "rectangle.stack.badge.person.crop"
                )
                .font(.title2)
                .foregroundStyle(
                    ChatDesign.accent
                )

                Spacer()

                Text(
                    "\(connectedCount)/\(sessions.count)"
                )
                .font(
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(.secondary)
            }

            Text("WhatsApp Accounts")
                .font(.headline)

            Text(
                "Each conversation keeps the account it arrived through."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            ChatDesign.subtleFill,
            in: RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
    }
}
