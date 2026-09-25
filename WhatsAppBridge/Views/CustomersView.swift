import SwiftUI

struct CustomersView: View {
    @State private var conversations: [Conversation] = []
    @State private var searchText = ""

    private var filtered: [Conversation] {
        conversations
            .filter {
                searchText.isEmpty ||
                $0.displayName
                    .localizedCaseInsensitiveContains(
                        searchText
                    ) ||
                $0.jid
                    .localizedCaseInsensitiveContains(
                        searchText
                    )
            }
            .sorted {
                $0.lastMessageAt >
                $1.lastMessageAt
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "No Customers",
                        systemImage: "person.2",
                        description: Text(
                            "Customers will appear here when conversations are available."
                        )
                    )
                }

                ForEach(
                    filtered,
                    id: \.jid
                ) { conversation in

                    NavigationLink {
                        CustomerInfoView(
                            conversation: conversation
                        )
                    } label: {
                        HStack(spacing: 12) {

                            AsyncImage(
                                url: APIClient.shared
                                    .avatarURL(
                                        for: conversation.jid
                                    )
                            ) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                Color.secondary
                                                    .opacity(0.15)
                                            )

                                        Text(
                                            conversation.initials
                                        )
                                        .font(.headline)
                                    }
                                }
                            }
                            .frame(
                                width: 48,
                                height: 48
                            )
                            .clipShape(Circle())

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {
                                Text(
                                    conversation.displayName
                                )
                                .font(.headline)

                                Text(
                                    conversation.jid
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                                .lineLimit(1)
                            }

                            Spacer()

                            if conversation.unread > 0 {
                                Text(
                                    "\(conversation.unread)"
                                )
                                .font(.caption.bold())
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(
                                            Color.accentColor
                                        )
                                )
                                .foregroundStyle(.white)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            .navigationTitle("Customers")
            .searchable(
                text: $searchText,
                prompt: "Search customers"
            )
            .refreshable {
                await load()
            }
            .task {
                await load()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .bridgeRealtimeUpdate
                )
            ) { _ in
                Task {
                    await load()
                }
            }
        }
    }

    @MainActor
    private func load() async {
        do {
            conversations =
                try await APIClient.shared
                    .fetchConversations()
        } catch {
        }
    }
}
