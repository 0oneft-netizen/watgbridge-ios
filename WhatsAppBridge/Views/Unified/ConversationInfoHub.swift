import SwiftUI

struct ConversationInfoHub: View {
    let conversation: Conversation
    let messages: [Message]

    @ObservedObject
    private var sessions = SessionDirectory.shared

    private var customerName: String {
        ChatIdentity.customerName(
            conversation: conversation
        )
    }

    private var customerPhone: String {
        ChatIdentity.customerPhone(
            from: conversation.jid
        )
    }

    private var sessionName: String {
        sessions.name(
            for: conversation.accountID ?? "default"
        )
    }

    private var media: [Message] {
        messages.filter {
            ["image", "video", "gif", "video_note"]
                .contains($0.type) &&
            !MessageMediaPolicy.isViewOnce($0)
        }
    }

    private var documents: [Message] {
        messages.filter {
            $0.type == "document"
        }
    }

    private var links: [String] {
        messages
            .flatMap {
                $0.text
                    .split(whereSeparator: \.isWhitespace)
                    .map(String.init)
            }
            .filter {
                $0.hasPrefix("https://") ||
                $0.hasPrefix("http://")
            }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                Color.secondary.opacity(0.12)
                            )

                        Image(systemName: "person.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 88, height: 88)

                    Text(customerName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(customerPhone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !sessionName.isEmpty {
                        Label(
                            sessionName,
                            systemImage:
                                "rectangle.stack.badge.person.crop"
                        )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section("Shared content") {
                NavigationLink {
                    ConversationMediaBrowser(
                        messages: media
                    )
                } label: {
                    infoRow(
                        "Media",
                        icon: "photo.on.rectangle",
                        count: media.count
                    )
                }

                NavigationLink {
                    ConversationDocumentBrowser(
                        messages: documents
                    )
                } label: {
                    infoRow(
                        "Documents",
                        icon: "doc",
                        count: documents.count
                    )
                }

                NavigationLink {
                    ConversationLinksView(
                        links: links
                    )
                } label: {
                    infoRow(
                        "Links",
                        icon: "link",
                        count: links.count
                    )
                }
            }

            Section("Conversation") {
                LabeledContent(
                    "Session",
                    value: sessionName
                )

                LabeledContent(
                    "Account ID",
                    value:
                        conversation.accountID
                        ?? "default"
                )
            }
        }
        .navigationTitle("Contact Info")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await sessions.refresh()
        }
    }

    private func infoRow(
        _ title: String,
        icon: String,
        count: Int
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)

            Text(title)

            Spacer()

            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }
}
