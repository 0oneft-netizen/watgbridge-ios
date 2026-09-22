import SwiftUI

struct ForwardMessageView: View {
    let message: Message

    @Environment(\.dismiss)
    private var dismiss

    @State private var conversations: [Conversation] = []
    @State private var searchText = ""
    @State private var sending = false

    private var visible: [Conversation] {
        conversations
            .filter { $0.archived != true }
            .filter {
                searchText.isEmpty ||
                $0.displayName.localizedCaseInsensitiveContains(
                    searchText
                )
            }
    }

    var body: some View {
        NavigationStack {
            List(visible) { conversation in
                Button {
                    Task {
                        await forward(
                            to: conversation
                        )
                    }
                } label: {
                    HStack {
                        Text(
                            conversation.displayName
                        )

                        Spacer()

                        Image(
                            systemName:
                                "paperplane"
                        )
                    }
                }
                .disabled(sending)
            }
            .navigationTitle("Forward to")
            .searchable(
                text: $searchText
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .topBarLeading
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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

    @MainActor
    private func forward(
        to conversation: Conversation
    ) async {
        guard !sending else {
            return
        }

        sending = true

        let text: String

        if message.text.isEmpty {
            text = "Forwarded \(message.type)"
        } else {
            text = message.text
        }

        do {
            try await APIClient.shared
                .sendMessage(
                    chatJID:
                        conversation.jid,
                    text: text
                )

            dismiss()

        } catch {
            sending = false
        }
    }
}
