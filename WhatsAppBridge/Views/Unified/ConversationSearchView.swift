import SwiftUI

struct ConversationSearchView: View {
    let conversation: Conversation

    @State
    private var query = ""

    @State
    private var results: [Message] = []

    @State
    private var loading = false

    @State
    private var errorText: String?

    var body: some View {
        Group {
            if loading && results.isEmpty {
                ProgressView()
            } else if let errorText,
                      results.isEmpty {
                ContentUnavailableView(
                    "Search Failed",
                    systemImage:
                        "exclamationmark.magnifyingglass",
                    description:
                        Text(errorText)
                )
            } else if query
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty {
                ContentUnavailableView(
                    "Search Messages",
                    systemImage:
                        "magnifyingglass",
                    description:
                        Text(
                            "Search messages in this conversation."
                        )
                )
            } else if results.isEmpty {
                ContentUnavailableView.search(
                    text: query
                )
            } else {
                List(results) {
                    message in

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        Text(
                            MessagePresentation
                                .fallbackText(
                                    for: message
                                )
                        )
                        .lineLimit(3)

                        Text(
                            MessageDatePresentation
                                .dayLabel(
                                    message.createdAt
                                )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .searchable(
            text: $query,
            prompt: "Search messages"
        )
        .onSubmit(of: .search) {
            Task {
                await performSearch()
            }
        }
    }

    @MainActor
    private func performSearch() async {
        let value = query
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !value.isEmpty else {
            results = []
            return
        }

        loading = true
        errorText = nil

        do {
            results =
                try await APIClient.shared
                    .searchMessages(
                        chatJID:
                            conversation.jid,
                        query: value,
                        accountID:
                            conversation
                                .accountID
                            ?? "default"
                    )
        } catch {
            errorText =
                AppErrorPresentation
                    .message(for: error)
        }

        loading = false
    }
}
