import SwiftUI

struct InboxStateView: View {
    let searching: Bool
    let hasAccounts: Bool

    var body: some View {
        if searching {
            ContentUnavailableView(
                "No Results",
                systemImage:
                    "magnifyingglass",
                description:
                    Text(
                        "Try another customer name or number."
                    )
            )

        } else if !hasAccounts {
            ContentUnavailableView(
                "No WhatsApp Accounts",
                systemImage:
                    "message.badge",
                description:
                    Text(
                        "Connect an account from Sessions."
                    )
            )

        } else {
            ContentUnavailableView(
                "No Conversations",
                systemImage:
                    "message",
                description:
                    Text(
                        "New conversations will appear here."
                    )
            )
        }
    }
}
