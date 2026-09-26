import SwiftUI

struct QuickReplyEditorView: View {
    @ObservedObject
    private var store =
        QuickReplyStore.shared

    @State
    private var shortcut = ""

    @State
    private var text = ""

    var body: some View {
        List {
            Section(
                "New quick reply"
            ) {
                HStack {
                    Text("/")
                        .foregroundStyle(
                            .secondary
                        )

                    TextField(
                        "shortcut",
                        text: $shortcut
                    )
                    .textInputAutocapitalization(
                        .never
                    )
                    .autocorrectionDisabled()
                }

                TextEditor(
                    text: $text
                )
                .frame(
                    minHeight: 90
                )

                Button(
                    "Add Quick Reply"
                ) {
                    store.add(
                        shortcut:
                            shortcut,
                        text: text
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
                "Saved replies"
            ) {
                if store.replies.isEmpty {
                    Text(
                        "No quick replies yet."
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                ForEach(
                    store.replies
                ) { reply in

                    VStack(
                        alignment:
                            .leading,
                        spacing: 4
                    ) {
                        Text(
                            "/"
                            + reply.shortcut
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
                            store.delete(
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
