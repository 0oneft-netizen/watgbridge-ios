import SwiftUI

struct ConversationsView: View {
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && conversations.isEmpty {
                    ProgressView()
                } else if let errorMessage, conversations.isEmpty {
                    ContentUnavailableView(
                        "Couldn't Load Chats",
                        systemImage: "wifi.exclamationmark",
                        description: Text(errorMessage)
                    )
                } else {
                    List {
                        ForEach(sortedConversations) { conversation in
                            NavigationLink {
                                ChatView(conversation: conversation)
                            } label: {
                                ConversationRow(conversation: conversation)
                            }
                            .swipeActions(
                                edge: .leading,
                                allowsFullSwipe: false
                            ) {
                                Button {
                                    Task {
                                        try? await APIClient.shared
                                            .conversationAction(
                                                chatJID: conversation.jid,
                                                action: "pin",
                                                value: !(conversation.pinned ?? false)
                                            )
                                        await loadConversations()
                                    }
                                } label: {
                                    Label(
                                        conversation.pinned == true
                                        ? "Unpin"
                                        : "Pin",
                                        systemImage: "pin.fill"
                                    )
                                }
                            }

                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: false
                            ) {
                                Button {
                                    Task {
                                        try? await APIClient.shared
                                            .conversationAction(
                                                chatJID: conversation.jid,
                                                action: "archive",
                                                value: !(conversation.archived ?? false)
                                            )
                                        await loadConversations()
                                    }
                                } label: {
                                    Label(
                                        conversation.archived == true
                                        ? "Unarchive"
                                        : "Archive",
                                        systemImage: "archivebox"
                                    )
                                }
                            }

                            .listRowSeparator(.visible)
                            .listRowInsets(
                                EdgeInsets(
                                    top: 8,
                                    leading: 16,
                                    bottom: 8,
                                    trailing: 12
                                )
                            )
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await loadConversations()
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit") {
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "camera")
                    }

                    Button {
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await loadConversations()
            }
        }
    }

    private var sortedConversations: [Conversation] {
        conversations.sorted {
            if $0.lastMessageAt == $1.lastMessageAt {
                return $0.displayName.localizedCaseInsensitiveCompare(
                    $1.displayName
                ) == .orderedAscending
            }

            return $0.lastMessageAt > $1.lastMessageAt
        }
    }

    @MainActor
    private func loadConversations() async {
        if conversations.isEmpty {
            isLoading = true
        }

        do {
            conversations = try await APIClient.shared.fetchConversations()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}


private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            avatar

            VStack(spacing: 4) {
                HStack {
                    Text(conversation.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if conversation.lastMessageAt > 0 {
                        Text(timeText)
                            .font(.caption)
                            .foregroundStyle(
                                conversation.unread > 0
                                ? Color.green
                                : Color.secondary
                            )
                    }
                }

                HStack(spacing: 6) {
                    Text(conversation.previewText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    if conversation.unread > 0 {
                        Text(
                            conversation.unread > 99
                            ? "99+"
                            : "\(conversation.unread)"
                        )
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Color.green)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = APIClient.shared.avatarURL(for: conversation.jid) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                default:
                    avatarFallback
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
        } else {
            avatarFallback
        }
    }

    private var avatarFallback: some View {
        ZStack {
            Circle()
                .fill(Color.secondary.opacity(0.18))

            Text(conversation.initials)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(width: 52, height: 52)
    }

    private var timeText: String {
        guard conversation.lastMessageAt > 0 else {
            return ""
        }

        let date = Date(
            timeIntervalSince1970: TimeInterval(conversation.lastMessageAt)
        )

        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return date.formatted(
                date: .omitted,
                time: .shortened
            )
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        if let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: Date())
        ).day,
           days < 7 {
            return date.formatted(.dateTime.weekday(.abbreviated))
        }

        return date.formatted(
            .dateTime
                .day()
                .month(.twoDigits)
        )
    }
}
