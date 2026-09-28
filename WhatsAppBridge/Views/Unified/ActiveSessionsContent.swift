import SwiftUI

struct ActiveSessionsContent: View {
    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    @StateObject
    private var live =
        SessionLiveStatusCoordinator()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tap a session to rename, disconnect, or delete it.")
                .font(.caption)
                .foregroundStyle(.secondary)

            sessionsContent
        }
    }

    @ViewBuilder
    private var sessionsContent: some View {
        List {
            ForEach(
                SessionSorting
                    .sorted(
                        sessions.accounts
                    )
                    .map { session in
                        SessionAccountDTO(
                            id: session.id,
                            displayName: session.name,
                            phone: session.phone,
                            jid: session.jid,
                            status: session.status,
                            accountType: session.accountType
                        )
                    }
            ) { account in

                NavigationLink {
                    SessionAccountDetailView(
                        account:
                            account
                    )
                } label: {
                    ProductionSessionRow(
                        account:
                            account
                    )
                }
            }
        }
        .task {
            await sessions.refresh()
            live.start()
        }
        .onDisappear {
            live.stop()
        }
        .refreshable {
            await sessions.refresh()
        }
    }
}
