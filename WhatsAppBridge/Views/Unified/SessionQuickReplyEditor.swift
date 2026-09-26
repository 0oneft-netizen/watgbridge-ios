import SwiftUI

struct SessionQuickReplyEditor: View {
    let accountID: String
    let sessionName: String

    @ObservedObject
    private var store =
        SessionQuickReplyStore.shared

    @State
    private var shortcut = ""

    @State
    private var text = ""

    var body: some View {
        List {
            Section(
                sessionName
            ) {
                TextField(
                    "Shortcut",
                    text:
                        $shortcut
                )

                TextField(
                    "Reply",
                    text:
                        $text,
                    axis:
                        .vertical
                )
                .lineLimit(
                    2...6
                )

                Button(
                    "Add"
                ) {
                    store.add(
                        accountID:
                            accountID,
                        shortcut:
                            shortcut,
                        text:
                            text
                    )

                    shortcut = ""
                    text = ""
                }
                .disabled(
                    shortcut
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
                    ||
                    text
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
                )
            }

            Section(
                "Replies"
            ) {
                ForEach(
                    store.replies(
                        accountID:
                            accountID
                    )
                ) { reply in

                    VStack(
                        alignment:
                            .leading,
                        spacing: 4
                    ) {
                        Text(
                            "/"
                            +
                            reply.shortcut
                        )
                        .font(
                            .headline
                        )

                        Text(
                            reply.text
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    .swipeActions {
                        Button(
                            role:
                                .destructive
                        ) {
                            store.remove(
                                id:
                                    reply.id
                            )
                        } label: {
                            Label(
                                "Delete",
                                systemImage:
                                    "trash"
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(
            "Quick Replies"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
