import SwiftUI

struct ArchivedConversationsView: View {
    @State private var conversations:
        [Conversation] = []

    var body: some View {
        List {
            ForEach(
                conversations.filter {
                    $0.archived == true
                }
            ) { conversation in

                NavigationLink {
                    ChatView(
                        conversation:
                            conversation
                    )
                } label: {
                    VStack(
                        alignment: .leading
                    ) {
                        Text(
                            conversation.displayName
                        )
                        .font(.headline)

                        Text(
                            conversation.preview
                        )
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )
                        .lineLimit(1)
                    }
                }
            }
        }
        .navigationTitle("Archived")
        .task {
            do {
                conversations =
                    try await APIClient.shared
                        .fetchConversations()
            } catch {
            }
        }
    }
}
