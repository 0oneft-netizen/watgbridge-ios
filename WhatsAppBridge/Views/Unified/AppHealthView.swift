import SwiftUI

struct AppHealthView: View {
    @ObservedObject
    private var network =
        NetworkMonitor.shared

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    @ObservedObject
    private var outbox =
        PersistentOutbox.shared

    private var snapshot:
        AppHealthSnapshot {
        AppHealth.snapshot()
    }

    var body: some View {
        List {
            Section(
                "Connection"
            ) {
                LabeledContent(
                    "Network",
                    value:
                        network.isConnected
                        ? network
                            .interfaceName
                        : "Offline"
                )

                LabeledContent(
                    "Sessions",
                    value:
                        "\(snapshot.connectedSessions)/\(snapshot.sessionCount) connected"
                )

                LabeledContent(
                    "Outbox",
                    value:
                        "\(snapshot.outboxCount)"
                )
            }

            if snapshot.hasProblems {
                Section {
                    Label(
                        "Some services need attention.",
                        systemImage:
                            "exclamationmark.triangle"
                    )
                }
            } else {
                Section {
                    Label(
                        "App systems look healthy.",
                        systemImage:
                            "checkmark.circle"
                    )
                    .foregroundStyle(
                        .green
                    )
                }
            }
        }
        .navigationTitle(
            "App Health"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
