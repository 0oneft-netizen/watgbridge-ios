import SwiftUI

struct ConversationsView: View {
    @State private var conversations: [Conversation] = []
    @State private var searchText = ""
    @State private var showSettings = false

    @State private var notificationConversation:
        Conversation?

    private var sortedConversations: [Conversation] {
        conversations
            .filter { $0.archived != true }
            .filter {
                searchText.isEmpty ||
                $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.preview.localizedCaseInsensitiveContains(searchText)
            }
            .sorted {
                let leftPinned = $0.pinned == true
                let rightPinned = $1.pinned == true

                if leftPinned != rightPinned {
                    return leftPinned && !rightPinned
                }

                return $0.lastMessageAt > $1.lastMessageAt
            }
    }

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ArchivedConversationsView()
                } label: {
                    Label(
                        "Archived",
                        systemImage: "archivebox"
                    )
                }

                ForEach(
                    sortedConversations,
                    id: \.compositeID
                ) { conversation in
                    NavigationLink {
                        ChatView(
                            conversation: conversation
                        )
                    } label: {
                        ConversationRow(
                            conversation: conversation
                        )
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
                                        value: !(conversation.pinned ?? false),
                                accountID: conversation.accountID ?? "default"
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

                        Button {
                            Task {
                                try? await APIClient.shared
                                    .conversationAction(
                                        chatJID: conversation.jid,
                                        action: "unread",
                                        value: true,
                                accountID: conversation.accountID ?? "default"
                                    )

                                await loadConversations()
                            }
                        } label: {
                            Label(
                                "Unread",
                                systemImage: "envelope.badge"
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
                                        value: !(conversation.archived ?? false),
                                accountID: conversation.accountID ?? "default"
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

                        Button {
                            Task {
                                try? await APIClient.shared
                                    .conversationAction(
                                        chatJID: conversation.jid,
                                        action: "mute",
                                        value: !(conversation.muted ?? false),
                                accountID: conversation.accountID ?? "default"
                                    )

                                await loadConversations()
                            }
                        } label: {
                            Label(
                                conversation.muted == true
                                ? "Unmute"
                                : "Mute",
                                systemImage: "speaker.slash"
                            )
                        }
                    }
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button {
                        Haptics.selection()
                        showSettings = true
                    } label: {
                        Image(
                            systemName: "gearshape"
                        )
                    }
                }
            }
            .sheet(
                isPresented: $showSettings
            ) {
                SettingsView()
            }
            .navigationDestination(
                item: $notificationConversation
            ) { conversation in
                ChatView(
                    conversation: conversation
                )
            }
            .searchable(
                text: $searchText,
                prompt: "Search"
            )
            .refreshable {
                await loadConversations()
            }
            .task {
                RealtimeClient.shared.start()

                await NotificationManager.shared
                    .requestPermission()

                await MainActor.run {
                    NotificationManager.shared
                        .registerForPushNotifications()
                }

                await loadConversations()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .bridgeRealtimeUpdate
                )
            ) { _ in
                Task {
                    await loadConversations()
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .bridgeIncomingMessage
                )
            ) { notification in
                guard let message =
                    notification.object
                        as? RealtimeIncomingMessage
                else {
                    return
                }

                let conversation =
                    conversations.first {
                        ($0.accountID ?? "default")
                            == message.account_id &&
                        $0.jid == message.chat_jid
                    }

                let muted =
                    conversation?.muted == true

                Task {
                    if !muted {
                        Haptics.incomingMessage()

                        let badge =
                            conversations.reduce(0) {
                                $0 + max(
                                    0,
                                    $1.unread
                                )
                            }

                        await NotificationManager.shared
                            .showIncoming(
                                message: message,
                                title:
                                    conversation?
                                        .displayName
                                    ?? "WhatsApp",
                                badge: badge
                            )
                    }

                    await loadConversations()
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for:
                        .openNotificationConversation
                )
            ) { notification in
                guard
                    let info =
                        notification.userInfo,
                    let accountID =
                        info["account_id"]
                            as? String,
                    let chatJID =
                        info["chat_jid"]
                            as? String
                else {
                    return
                }

                Task {
                    if let existing =
                        conversations.first(
                            where: {
                                ($0.accountID
                                    ?? "default")
                                    == accountID &&
                                $0.jid == chatJID
                            }
                        ) {
                        notificationConversation =
                            existing
                        return
                    }

                    await loadConversations()

                    notificationConversation =
                        conversations.first(
                            where: {
                                ($0.accountID
                                    ?? "default")
                                    == accountID &&
                                $0.jid == chatJID
                            }
                        )
                }
            }
        }
    }

    @MainActor
    private func loadConversations(
        notifyForNewMessages: Bool = false
    ) async {
        do {
            let old =
                Dictionary(
                    uniqueKeysWithValues:
                        conversations.map {
                            (
                                $0.jid,
                                $0.unread
                            )
                        }
                )

            let updated =
                try await APIClient.shared
                    .fetchConversations()

            // Incoming-message notifications are emitted
            // by the realtime message stream. Do not duplicate
            // them here when the conversation list refreshes.

            conversations = updated

            let unreadTotal =
                conversations.reduce(0) {
                    $0 + $1.unread
                }

            await NotificationManager.shared
                .setBadgeCount(
                    unreadTotal
                )

        } catch {
        }
    }
}

private struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(
                url: APIClient.shared
                    .avatarURL(
                        for: conversation.jid
                    )
            ) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                default:
                    ZStack {
                        Circle()
                            .fill(
                                Color.secondary
                                    .opacity(0.15)
                            )

                        Text(
                            conversation.initials
                        )
                        .font(
                            .headline
                        )
                    }
                }
            }
            .frame(
                width: 52,
                height: 52
            )
            .clipShape(
                Circle()
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                HStack(spacing: 5) {
                    Text(
                        conversation.displayName
                    )
                    .font(
                        .headline
                    )
                    .lineLimit(1)

                    if conversation.pinned == true {
                        Image(
                            systemName: "pin.fill"
                        )
                        .font(
                            .caption2
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    if conversation.muted == true {
                        Image(
                            systemName:
                                "speaker.slash.fill"
                        )
                        .font(
                            .caption2
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                    Spacer()
                }

                HStack {
                    Text(
                        conversation.lastMessage
                    )
                    .font(
                        .subheadline
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(1)

                    Spacer()

                    if conversation.unread > 0 {
                        Text(
                            "\(conversation.unread)"
                        )
                        .font(
                            .caption2
                                .bold()
                        )
                        .foregroundStyle(
                            .white
                        )
                        .padding(
                            .horizontal,
                            7
                        )
                        .padding(
                            .vertical,
                            3
                        )
                        .background(
                            Color.green
                        )
                        .clipShape(
                            Capsule()
                        )
                    }
                }
            }
        }
        .padding(
            .vertical,
            3
        )
    }
}

// BUILD_TRIGGER_REALTIME_FIX
