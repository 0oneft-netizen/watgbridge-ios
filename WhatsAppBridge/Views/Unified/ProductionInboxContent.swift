import SwiftUI

struct ProductionInboxContent: View {
    let conversations:
        [Conversation]

    @Binding
    var searchText:
        String

    @Binding
    var selectedAccountID:
        String?

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var visible:
        [Conversation] {

        ProductionInboxPipeline
            .visible(
                conversations:
                    conversations,
                query:
                    searchText,
                accountID:
                    selectedAccountID
            )
    }

    var body: some View {
        Group {
            if visible.isEmpty {
                InboxStateView(
                    searching:
                        !searchText
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                            .isEmpty,
                    hasAccounts:
                        !sessions
                            .accounts
                            .isEmpty
                )

            } else {
                List {
                    InboxWorkloadSummary(
                        conversations:
                            visible
                    )
                    .listRowSeparator(
                        .hidden
                    )

                    ForEach(
                        visible
                    ) { conversation in

                        NavigationLink {
                            ChatView(
                                conversation:
                                    conversation
                            )
                        } label: {
                            ActiveConversationRow(
                                conversation:
                                    conversation
                            )
                        }
                        .inboxSwipeActions(
                            conversation:
                                conversation
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
