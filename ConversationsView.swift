import SwiftUI

struct ConversationsView: View {
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading conversations...")
                } else if let errorMessage {
                    ContentUnavailableView(
                        "Connection Error",
                        systemImage: "wifi.exclamationmark",
                        description: Text(errorMessage)
                    )
                } else {
                    List(conversations) { conversation in
                        NavigationLink {
                            ChatView(conversation: conversation)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(conversation.name)
                                    .font(.headline)

                                Text(conversation.jid)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("WhatsApp")
            .task {
                await loadConversations()
            }
        }
    }

    private func loadConversations() async {
        do {
            conversations = try await APIClient.shared.fetchConversations()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
