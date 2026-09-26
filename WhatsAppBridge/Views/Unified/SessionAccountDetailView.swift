import SwiftUI

struct SessionAccountDetailView: View {
    let account:
        SessionAccountDTO

    var body: some View {
        List {
            Section {
                SessionDetailCard(
                    account:
                        account
                )
            }

            Section(
                "Tools"
            ) {
                NavigationLink {
                    RenameSessionView(
                        account:
                            account
                    )
                } label: {
                    Label(
                        "Rename Session",
                        systemImage:
                            "pencil"
                    )
                }

                NavigationLink {
                    SessionQuickReplyEditor(
                        accountID:
                            account.id,
                        sessionName:
                            account.displayName
                    )
                } label: {
                    Label(
                        "Quick Replies",
                        systemImage:
                            "bolt.fill"
                    )
                }
            }

            Section(
                "Connection"
            ) {
                SessionConnectionChip(
                    status:
                        account.status
                )

                Text(
                    "Renaming this session does not change its routing identity."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .navigationTitle(
            account.displayName
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
