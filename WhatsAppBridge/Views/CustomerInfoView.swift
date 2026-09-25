import SwiftUI

struct CustomerInfoView: View {
    let conversation: Conversation

    @State private var label = ""
    @State private var note = ""

    @State private var editing = false
    @State private var saving = false

    private let labels = [
        "New Lead",
        "Contacted",
        "Interested",
        "Waiting",
        "Customer",
        "Closed"
    ]

    var body: some View {
        Form {
            Section {
                VStack(spacing: 14) {
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
                                .font(.largeTitle.bold())
                            }
                        }
                    }
                    .frame(
                        width: 100,
                        height: 100
                    )
                    .clipShape(Circle())

                    Text(
                        conversation.displayName
                    )
                    .font(.title2.bold())

                    Text(conversation.jid)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 8)
            }

            Section("Business Status") {
                Picker(
                    "Label",
                    selection: $label
                ) {
                    Text("None")
                        .tag("")

                    ForEach(
                        labels,
                        id: \.self
                    ) { item in
                        Text(item)
                            .tag(item)
                    }
                }
            }

            Section("Internal Note") {
                TextEditor(
                    text: $note
                )
                .frame(
                    minHeight: 100
                )
            }

            Section {
                NavigationLink {
                    ChatView(
                        conversation: conversation
                    )
                } label: {
                    Label(
                        "Open Conversation",
                        systemImage: "message.fill"
                    )
                }

                Button {
                    Task {
                        try? await APIClient.shared
                            .conversationAction(
                                chatJID: conversation.jid,
                                action: "unread",
                                value: true
                            )

                        Haptics.success()
                    }
                } label: {
                    Label(
                        "Mark as Unread",
                        systemImage:
                            "envelope.badge"
                    )
                }

                Button {
                    Task {
                        try? await APIClient.shared
                            .conversationAction(
                                chatJID: conversation.jid,
                                action: "mute",
                                value:
                                    !(conversation.muted ?? false)
                            )

                        Haptics.success()
                    }
                } label: {
                    Label(
                        conversation.muted == true
                        ? "Unmute"
                        : "Mute",
                        systemImage:
                            "speaker.slash.fill"
                    )
                }

                Button {
                    Task {
                        try? await APIClient.shared
                            .conversationAction(
                                chatJID: conversation.jid,
                                action: "archive",
                                value:
                                    !(conversation.archived ?? false)
                            )

                        Haptics.success()
                    }
                } label: {
                    Label(
                        conversation.archived == true
                        ? "Unarchive"
                        : "Archive",
                        systemImage: "archivebox.fill"
                    )
                }
            }

            Section {
                Button {
                    Task {
                        await save()
                    }
                } label: {
                    if saving {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Text("Save Customer")
                            .frame(
                                maxWidth: .infinity
                            )
                    }
                }
                .disabled(saving)
            }
        }
        .navigationTitle("Customer Info")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        do {
            let meta =
                try await BusinessAPI.shared
                    .customer(
                        jid: conversation.jid
                    )

            label = meta.label
            note = meta.note
        } catch {
        }
    }

    @MainActor
    private func save() async {
        saving = true

        defer {
            saving = false
        }

        do {
            try await BusinessAPI.shared
                .saveCustomer(
                    jid: conversation.jid,
                    label: label,
                    note: note
                )

            Haptics.success()
        } catch {
            Haptics.error()
        }
    }
}
