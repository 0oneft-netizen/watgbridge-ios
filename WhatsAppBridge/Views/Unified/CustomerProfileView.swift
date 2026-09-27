import SwiftUI
import UIKit

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
            profileHeader

            Section {
                quickActions
            }
            .listRowInsets(
                EdgeInsets(
                    top: 10,
                    leading: 16,
                    bottom: 10,
                    trailing: 16
                )
            )

            Section {
                ProfileMediaStrip(
                    messages: messages
                )

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
                        messages: documents
                    )
                } label: {
                    profileRow(
                        "Documents",
                        icon: "doc.fill",
                        detail:
                            "\(documents.count)"
                    )
                }

                NavigationLink {
                    RichConversationLinksView(
                        messages: messages
                    )
                } label: {
                    profileRow(
                        "Links",
                        icon: "link",
                        detail:
                            "\(links.count)"
                    )
                }
            } header: {
                Text("Shared Content")
            }

            Section {
                NavigationLink {
                    CustomerBusinessInfoView(
                        conversation:
                            conversation
                    )
                } label: {
                    profileRow(
                        "Notes & Labels",
                        icon: "tag.fill",
                        detail: ""
                    )
                }

                NavigationLink {
                    StarredMessagesView(
                        messages: messages
                    )
                } label: {
                    profileRow(
                        "Starred Messages",
                        icon: "star.fill",
                        detail: ""
                    )
                }

                NavigationLink {
                    CustomerWorkflowEditor(
                        conversation:
                            conversation
                    )
                } label: {
                    profileRow(
                        "Workflow Status",
                        icon:
                            "checklist",
                        detail: ""
                    )
                }
            } header: {
                Text("Customer")
            }

            Section {
                CustomerConversationStats(
                    messages: messages
                )
            } header: {
                Text("Conversation")
            }

            Section {
                CustomerPhoneActions(
                    conversation:
                        conversation
                )

                ConversationRouteInfo(
                    conversation:
                        conversation
                )
            }

            CustomerProfileTools(
                conversation:
                    conversation,
                messages:
                    messages
            )

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

                Button {
                    UIPasteboard
                        .general
                        .string = phone

                    Haptics.success()
                } label: {
                    Label(
                        "Copy Phone Number",
                        systemImage:
                            "doc.on.doc"
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Contact Info")
        .navigationBarTitleDisplayMode(
            .inline
        )
        .tint(
            AppVisualDesign.accent
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

    private var profileHeader: some View {
        Section {
            VStack(spacing: 8) {
                Button {
                    showPhoto = true
                } label: {
                    CustomerAvatarView(
                        jid:
                            conversation.jid,
                        size: 112
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                Color.secondary
                                    .opacity(0.12),
                                lineWidth: 0.5
                            )
                    )
                }
                .buttonStyle(.plain)

                Text(name)
                    .font(
                        .system(
                            size: 23,
                            weight: .semibold
                        )
                    )
                    .multilineTextAlignment(
                        .center
                    )

                if !phone.isEmpty {
                    Text(phone)
                        .font(.body)
                        .foregroundStyle(
                            .secondary
                        )
                        .textSelection(
                            .enabled
                        )
                }

                if !session.isEmpty {
                    SessionMiniBadge(
                        name: session
                    )
                    .padding(.top, 1)
                }
            }
            .frame(
                maxWidth: .infinity
            )
            .padding(.vertical, 12)
        }
        .listRowBackground(
            Color.clear
        )
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            profileAction(
                title: "Message",
                icon: "message.fill"
            ) {
            }

            profileAction(
                title: "Call",
                icon: "phone.fill"
            ) {
            }
            .disabled(true)

            profileAction(
                title: "Search",
                icon:
                    "magnifyingglass"
            ) {
            }

            profileAction(
                title: "More",
                icon:
                    "ellipsis"
            ) {
            }
        }
        .frame(
            maxWidth: .infinity
        )
    }

    private func profileAction(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(
            action: action
        ) {
            VStack(spacing: 7) {
                Image(
                    systemName: icon
                )
                .font(
                    .system(
                        size: 18,
                        weight: .medium
                    )
                )
                .frame(height: 22)

                Text(title)
                    .font(
                        .system(
                            size: 11,
                            weight: .medium
                        )
                    )
                    .lineLimit(1)
            }
            .foregroundStyle(
                AppVisualDesign.accent
            )
            .frame(
                maxWidth: .infinity
            )
            .frame(height: 62)
            .background(
                Color(
                    uiColor:
                        .secondarySystemGroupedBackground
                ),
                in:
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
            )
        }
        .buttonStyle(.plain)
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
