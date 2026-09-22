import SwiftUI

struct ChatView: View {
    let conversation: Conversation

    @State private var messages: [Message] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var messageText = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if isLoading && messages.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if let errorMessage, messages.isEmpty {
                    ContentUnavailableView(
                        "Couldn't Load Messages",
                        systemImage: "wifi.exclamationmark",
                        description: Text(errorMessage)
                    )

                } else {
                    messageList
                }
            }

            composer
        }
        .navigationTitle(conversation.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    ChatAvatar(conversation: conversation)

                    Text(conversation.displayName)
                        .font(.headline)
                        .lineLimit(1)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "video")
                }

                Button {
                } label: {
                    Image(systemName: "phone")
                }
            }
        }
        .task {
            await loadMessages()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                await loadMessages()
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            .background(
                Color.secondary.opacity(0.06)
                    .ignoresSafeArea()
            )
            .refreshable {
                await loadMessages()
            }
            .onChange(of: messages.count) {
                scrollToBottom(proxy)
            }
            .onAppear {
                scrollToBottom(proxy)
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Button {
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $messageText, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)

                Button {
                } label: {
                    Image(systemName: "camera")
                        .font(.title3)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Color.secondary.opacity(0.10)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
            )

            if messageText.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty {
                Button {
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                }
            } else {
                Button {
                    Task {
                        await sendMessage()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                }
                .disabled(isSending)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @MainActor
    private func sendMessage() async {
        let text = messageText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

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

    @MainActor
    private func loadMessages() async {
        if messages.isEmpty {
            isLoading = true
        }

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

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = messages.last else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
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
                Text(message.text.isEmpty ? " " : message.text)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Spacer(minLength: 0)

                    Text(timeText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if message.fromMe {
                        Image(systemName: "checkmark.2")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                message.fromMe
                    ? Color.green.opacity(0.22)
                    : Color(.secondarySystemBackground)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
            )
            .frame(
                maxWidth: 300,
                alignment: message.fromMe ? .trailing : .leading
            )

            if !message.fromMe {
                Spacer(minLength: 50)
            }
        }
    }

    private var timeText: String {
        let date = Date(
            timeIntervalSince1970: TimeInterval(message.createdAt)
        )

        return date.formatted(
            date: .omitted,
            time: .shortened
        )
    }
}


private struct ChatAvatar: View {
    let conversation: Conversation

    var body: some View {
        Group {
            if let url = APIClient.shared.avatarURL(for: conversation.jid) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }

    private var fallback: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.18))

            Text(conversation.initials)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}
