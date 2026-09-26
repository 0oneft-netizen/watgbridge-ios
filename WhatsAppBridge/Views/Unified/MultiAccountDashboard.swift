import SwiftUI

struct MultiAccountDashboard: View {
    let conversations:
        [Conversation]

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var workloads:
        [SessionWorkload] {
        SessionWorkloadCalculator
            .calculate(
                conversations:
                    conversations
            )
    }

    var body: some View {
        List {
            Section(
                "Accounts"
            ) {
                ForEach(
                    workloads
                ) { workload in

                    SessionWorkloadCard(
                        name:
                            sessions.name(
                                for:
                                    workload
                                        .accountID
                            ),
                        workload:
                            workload
                    )
                    .listRowSeparator(
                        .hidden
                    )
                }
            }

            Section(
                "Routing"
            ) {
                Text(
                    "Each conversation stays bound to its original WhatsApp account."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                Text(
                    "Renaming an account changes only its display name."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .navigationTitle(
            "Account Workload"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
}
