import SwiftUI

struct SessionDiagnosticsView: View {
    let conversations:
        [Conversation]

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var values:
        [SessionDiagnosticSnapshot] {
        SessionDiagnostics
            .snapshots(
                accounts:
                    sessions.accounts,
                conversations:
                    conversations
            )
    }

    var body: some View {
        List {
            ForEach(values) {
                item in

                Section(
                    item.displayName
                ) {
                    LabeledContent(
                        "Status",
                        value:
                            item.status
                    )

                    LabeledContent(
                        "Type",
                        value:
                            AccountTypePresentation
                                .title(
                                    item
                                        .accountType
                                )
                    )

                    LabeledContent(
                        "Chats",
                        value:
                            "\(item.conversationCount)"
                    )

                    LabeledContent(
                        "Unread",
                        value:
                            "\(item.unreadCount)"
                    )
                }
            }

            Section {
                Text(
                    "Internal account identifiers are intentionally hidden from this screen."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .navigationTitle(
            "Diagnostics"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
