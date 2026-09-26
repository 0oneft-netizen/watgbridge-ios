import SwiftUI

struct CustomerProfileSections: View {
    let conversation:
        Conversation

    let messages:
        [Message]

    var body: some View {
        Section {
            CustomerProfileSummary(
                conversation:
                    conversation,
                messages:
                    messages
            )

            CustomerActionGrid(
                conversation:
                    conversation
            )
        }

        Section(
            "Business"
        ) {
            CustomerBusinessInfoView(
                conversation:
                    conversation
            )

            CustomerWorkflowEditor(
                conversation:
                    conversation
            )

            CustomerFollowUpView(
                conversation:
                    conversation
            )
        }

        Section(
            "Conversation"
        ) {
            NavigationLink {
                ConversationMediaBrowser(
                    messages:
                        ProfileMediaFilter
                            .media(
                                messages
                            )
                )
            } label: {
                Label(
                    "Media",
                    systemImage:
                        "photo.on.rectangle"
                )
            }

            NavigationLink {
                ConversationDocumentBrowser(
                    messages:
                        ProfileMediaFilter
                            .documents(
                                messages
                            )
                )
            } label: {
                Label(
                    "Documents",
                    systemImage:
                        "doc"
                )
            }

            NavigationLink {
                RichConversationLinksView(
                    messages:
                        messages
                )
            } label: {
                Label(
                    "Links",
                    systemImage:
                        "link"
                )
            }

            NavigationLink {
                StarredMessagesView(
                    messages:
                        messages
                )
            } label: {
                Label(
                    "Starred Messages",
                    systemImage:
                        "star"
                )
            }
        }
    }
}
