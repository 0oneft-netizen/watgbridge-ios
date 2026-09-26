import SwiftUI

struct ActiveConversationRow: View {
    let conversation:
        Conversation

    var body: some View {
        ProductionInboxRowV2(
            conversation:
                conversation
        )
        .contextMenu {
            CustomerOperationMenu(
                conversation:
                    conversation
            )
        }
    }
}
