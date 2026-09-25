import SwiftUI

struct LiveCustomerSessionHeader: View {
    let conversation: Conversation

    @ObservedObject
    private var directory =
        SessionDirectory.shared

    private var accountID: String {
        conversation.accountID
        ?? "default"
    }

    private var sessionName: String {
        directory.name(
            for: accountID
        )
    }

    var body: some View {
        CustomerSessionHeader(
            customerName:
                ChatIdentity.customerName(
                    conversation: conversation
                ),
            customerPhone:
                ChatIdentity.customerPhone(
                    from: conversation.jid
                ),
            sessionName: sessionName
        )
    }
}
