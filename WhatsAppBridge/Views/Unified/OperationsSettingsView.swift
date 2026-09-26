import SwiftUI

struct OperationsSettingsView: View {
    let conversations:
        [Conversation]

    var body: some View {
        List {
            Section(
                "Operations"
            ) {
                NavigationLink {
                    MultiAccountDashboard(
                        conversations:
                            conversations
                    )
                } label: {
                    Label(
                        "Account Workload",
                        systemImage:
                            "rectangle.stack"
                    )
                }

                NavigationLink {
                    SessionDiagnosticsView(
                        conversations:
                            conversations
                    )
                } label: {
                    Label(
                        "Session Diagnostics",
                        systemImage:
                            "stethoscope"
                    )
                }

                NavigationLink {
                    OutboxView()
                } label: {
                    Label(
                        "Outbox",
                        systemImage:
                            "paperplane"
                    )
                }

                NavigationLink {
                    AppHealthView()
                } label: {
                    Label(
                        "App Health",
                        systemImage:
                            "heart.text.square"
                    )
                }

                NavigationLink {
                    StorageManagementView()
                } label: {
                    Label(
                        "Storage",
                        systemImage:
                            "internaldrive"
                    )
                }
            }
        }
        .navigationTitle(
            "Operations"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
