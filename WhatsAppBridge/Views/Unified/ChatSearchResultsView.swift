import SwiftUI

struct ChatSearchResultsView: View {
    let messages: [Message]
    let select: (Message) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var query = ""

    private var results:
        [Message] {
        ChatSearchEngine.results(
            query: query,
            messages: messages
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if query.isEmpty {
                    ContentUnavailableView(
                        "Search Messages",
                        systemImage:
                            "magnifyingglass",
                        description:
                            Text(
                                "Search text and document names."
                            )
                    )
                } else if results.isEmpty {
                    ContentUnavailableView
                        .search(
                            text: query
                        )
                } else {
                    List(results) {
                        message in

                        Button {
                            select(message)
                            dismiss()
                        } label: {
                            VStack(
                                alignment:
                                    .leading,
                                spacing: 5
                            ) {
                                SearchHighlightedText(
                                    text:
                                        MessageTypePresentation
                                            .label(
                                                for:
                                                    message
                                            ),
                                    query:
                                        query
                                )
                                .foregroundStyle(
                                    .primary
                                )
                                .lineLimit(3)

                                Text(
                                    Date(
                                        timeIntervalSince1970:
                                            TimeInterval(
                                                message.createdAt
                                            )
                                    )
                                    .formatted(
                                        date:
                                            .abbreviated,
                                        time:
                                            .shortened
                                    )
                                )
                                .font(.caption2)
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                            .padding(
                                .vertical,
                                3
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(
                "Search"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .searchable(
                text: $query,
                placement:
                    .navigationBarDrawer(
                        displayMode:
                            .always
                    )
            )
        }
    }
}
