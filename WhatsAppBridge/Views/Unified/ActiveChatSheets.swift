import SwiftUI

struct ActiveChatProfileSheet: View {
    let conversation:
        Conversation

    let messages:
        [Message]

    var body: some View {
        NavigationStack {
            List {
                CustomerProfileSections(
                    conversation:
                        conversation,
                    messages:
                        messages
                )
            }
            .navigationTitle(
                "Contact Info"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
        }
    }
}
