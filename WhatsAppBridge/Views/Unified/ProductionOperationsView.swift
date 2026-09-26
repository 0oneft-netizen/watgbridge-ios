import SwiftUI

struct ProductionOperationsView: View {
    let conversations:
        [Conversation]

    var body: some View {
        List {
            Section(
                "WhatsApp Accounts"
            ) {
                NavigationLink {
                    SessionsManagementView()
                } label: {
                    Label(
                        "Sessions",
                        systemImage:
                            "rectangle.stack"
                    )
                }

                NavigationLink {
                    MultiAccountDashboard(
                        conversations:
                            conversations
                    )
                } label: {
                    Label(
                        "Workload",
                        systemImage:
                            "chart.bar"
                    )
                }

                NavigationLink {
                    SessionDiagnosticsView(
                        conversations:
                            conversations
                    )
                } label: {
                    Label(
                        "Diagnostics",
                        systemImage:
                            "waveform.path.ecg"
                    )
                }
            }

            Section(
                "Reliability"
            ) {
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
    }
}
