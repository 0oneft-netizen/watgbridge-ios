import SwiftUI

struct CustomerProfileView: View {
    let conversation: Conversation
    let messages: [Message]

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    @State
    private var showPhoto = false

    private var name: String {
        ChatIdentity.customerName(
            conversation: conversation
        )
    }

    private var phone: String {
        ChatIdentity.customerPhone(
            from: conversation.jid
        )
    }

    private var session: String {
        sessions.name(
            for:
                conversation.accountID
                ?? "default"
        )
    }

    private var media: [Message] {
        messages.filter {
            [
                "image",
                "video",
                "gif",
                "video_note"
            ].contains($0.type)
            &&
            !MessageMediaPolicy
                .isViewOnce($0)
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
                    .split(
                        whereSeparator:
                            \.isWhitespace
                    )
                    .map(String.init)
            }
            .filter {
                $0.hasPrefix(
                    "https://"
                ) ||
                $0.hasPrefix(
                    "http://"
                )
            }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Button {
                        showPhoto = true
                    } label: {
                        CustomerAvatarView(
                            jid:
                                conversation.jid,
                            size: 104
                        )
                    }
                    .buttonStyle(.plain)

                    Text(name)
                        .font(
                            .title2.bold()
                        )
                        .multilineTextAlignment(
                            .center
                        )

                    Text(phone)
                        .font(.body)
                        .foregroundStyle(
                            .secondary
                        )

                    if !session.isEmpty {
                        Text(session)
                            .font(
                                .caption.weight(
                                    .semibold
                                )
                            )
                            .foregroundStyle(
                                .secondary
                            )
                    }
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 12)
                .listRowBackground(
                    Color.clear
                )
            }

            Section {
                NavigationLink {
                    ConversationMediaBrowser(
                        messages: media
                    )
                } label: {
                    profileRow(
                        "Media",
                        icon:
                            "photo.on.rectangle",
                        detail:
                            "\(media.count)"
                    )
                }

                NavigationLink {
                    ConversationDocumentBrowser(
                        messages:
                            documents
                    )
                } label: {
                    profileRow(
                        "Documents",
                        icon: "doc",
                        detail:
                            "\(documents.count)"
                    )
                }

                NavigationLink {
                    ConversationLinksView(
                        links: links
                    )
                } label: {
                    profileRow(
                        "Links",
                        icon: "link",
                        detail:
                            "\(links.count)"
                    )
                }
            }

            Section("Contact") {
                LabeledContent(
                    "Phone",
                    value: phone
                )

                if !session.isEmpty {
                    LabeledContent(
                        "Received via",
                        value: session
                    )
                }
            }

            Section {
                Button {
                    UIPasteboard
                        .general
                        .string = phone
                } label: {
                    Label(
                        "Copy phone number",
                        systemImage:
                            "doc.on.doc"
                    )
                }
            }
        }
        .navigationTitle(
            "Contact Info"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
        .sheet(
            isPresented: $showPhoto
        ) {
            ProfilePhotoViewer(
                jid:
                    conversation.jid,
                customerName:
                    name
            )
        }
        .task {
            await sessions.refresh()
        }
    }

    private func profileRow(
        _ title: String,
        icon: String,
        detail: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)

            Text(title)

            Spacer()

            Text(detail)
                .foregroundStyle(
                    .secondary
                )
        }
    }
}
