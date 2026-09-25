import SwiftUI

struct QuickRepliesView: View {
    @State private var replies:
        [BusinessQuickReply] = []

    @State private var shortcut = ""
    @State private var message = ""

    @State private var saving = false

    var body: some View {
        List {
            Section("Quick Replies") {
                if replies.isEmpty {
                    ContentUnavailableView(
                        "No Quick Replies",
                        systemImage:
                            "text.bubble"
                    )
                }

                ForEach(replies) { reply in
                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text(
                            "/\(reply.shortcut)"
                        )
                        .font(.headline)

                        Text(reply.message)
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }
            }

            Section("Add Quick Reply") {
                TextField(
                    "Shortcut",
                    text: $shortcut
                )
                .textInputAutocapitalization(
                    .never
                )

                TextField(
                    "Message",
                    text: $message,
                    axis: .vertical
                )

                Button("Save") {
                    Task {
                        await save()
                    }
                }
                .disabled(
                    shortcut
                        .trimmingCharacters(
                            in: .whitespaces
                        )
                        .isEmpty ||
                    message
                        .trimmingCharacters(
                            in: .whitespaces
                        )
                        .isEmpty ||
                    saving
                )
            }
        }
        .navigationTitle(
            "Quick Replies"
        )
        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        replies =
            (try? await
                BusinessAPI.shared
                    .quickReplies()
            ) ?? []
    }

    @MainActor
    private func save() async {
        saving = true

        defer {
            saving = false
        }

        try? await
            BusinessAPI.shared
                .saveQuickReply(
                    shortcut:
                        shortcut
                        .trimmingCharacters(
                            in: .whitespaces
                        ),
                    message:
                        message
                        .trimmingCharacters(
                            in: .whitespaces
                        )
                )

        shortcut = ""
        message = ""

        Haptics.success()

        await load()
    }
}
