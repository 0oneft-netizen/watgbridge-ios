import SwiftUI

struct ChatView: View {
    let conversation: Conversation

    @State private var messages: [Message] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var messageText = ""
    @State private var isSending = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading messages...")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Connection Error",
                    systemImage: "wifi.exclamationmark",
                    description: Text(errorMessage)
                )
            } else if messages.isEmpty {
                ContentUnavailableView(
                    "No Messages",
                    systemImage: "message",
                    description: Text("No messages have been captured for this chat yet.")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 10) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                }
                .disabled(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    isSending
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .navigationTitle(conversation.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMessages()
        }
        .refreshable {
            await loadMessages()
        }
    }

    private func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty, !isSending else {
            return
        }

        isSending = true

        do {
            try await APIClient.shared.sendMessage(
                chatJID: conversation.jid,
                text: text
            )

            messageText = ""
            errorMessage = nil

            try? await Task.sleep(for: .milliseconds(500))
            await loadMessages()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }

    private func loadMessages() async {
        do {
            messages = try await APIClient.shared.fetchMessages(
                chatJID: conversation.jid
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

private struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.fromMe {
                Spacer(minLength: 50)
            }

            VStack(alignment: .leading, spacing: 4) {
                if message.text.isEmpty {
                    Text("Media")
                        .italic()
                } else {
                    Text(message.text)
                }

                Text(dateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                message.fromMe
                    ? Color.green.opacity(0.22)
                    : Color.secondary.opacity(0.14)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if !message.fromMe {
                Spacer(minLength: 50)
            }
        }
    }

    private var dateText: String {
        let date = Date(timeIntervalSince1970: TimeInterval(message.createdAt))
        return date.formatted(date: .omitted, time: .shortened)
    }
}
