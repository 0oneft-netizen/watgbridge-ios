import SwiftUI

struct ProductionInboxToolbar: View {
    @Binding
    var selectedAccountID:
        String?

    let conversations:
        [Conversation]

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    var body: some View {
        HStack(spacing: 10) {
            InboxAccountPicker(
                accountID:
                    $selectedAccountID
            )

            Spacer()

            NavigationLink {
                MultiAccountDashboard(
                    conversations:
                        conversations
                )
            } label: {
                Image(
                    systemName:
                        "chart.bar.xaxis"
                )
            }

            NavigationLink {
                SessionsManagementView()
            } label: {
                Image(
                    systemName:
                        "rectangle.stack.badge.person.crop"
                )
            }
        }
    }
}
