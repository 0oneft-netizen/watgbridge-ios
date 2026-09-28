import SwiftUI

struct ActiveSessionsContent: View {
    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    @StateObject
    private var live =
        SessionLiveStatusCoordinator()

    @State
    private var selectedAccount:
        SessionAccountDTO?

    private var accounts:
        [SessionAccountDTO] {

        SessionSorting
            .sorted(
                sessions.accounts
            )
            .map { session in
                SessionAccountDTO(
                    id: session.id,
                    displayName:
                        session.name,
                    phone:
                        session.phone,
                    jid:
                        session.jid,
                    status:
                        session.status,
                    accountType:
                        session.accountType
                )
            }
    }

    var body: some View {
        List {
            Section {
                ForEach(accounts) { account in
                    NavigationLink {
                        SessionAccountDetailView(
                            account: account
                        )
                    } label: {
                        ProductionSessionRow(
                            account: account
                        )
                    }
                    .contextMenu {
                        Button {
                            selectedAccount =
                                account
                        } label: {
                            Label(
                                "Manage Session",
                                systemImage:
                                    "gearshape"
                            )
                        }

                        if account.id != "default" {
                            Button(
                                role: .destructive
                            ) {
                                selectedAccount =
                                    account
                            } label: {
                                Label(
                                    "Delete Session…",
                                    systemImage:
                                        "trash"
                                )
                            }
                        }
                    }
                    .swipeActions(
                        edge: .trailing,
                        allowsFullSwipe: false
                    ) {
                        if account.id != "default" {
                            Button(
                                role: .destructive
                            ) {
                                selectedAccount =
                                    account
                            } label: {
                                Label(
                                    "Delete",
                                    systemImage:
                                        "trash"
                                )
                            }
                        }

                        Button {
                            selectedAccount =
                                account
                        } label: {
                            Label(
                                "Manage",
                                systemImage:
                                    "gearshape"
                            )
                        }
                        .tint(.gray)
                    }
                }
            } header: {
                Text("WhatsApp Accounts")
            } footer: {
                Text(
                    "Tap an account to manage it. Swipe left on a non-primary account for Delete."
                )
            }
        }
        .navigationDestination(
            item: $selectedAccount
        ) { account in
            SessionAccountDetailView(
                account: account
            )
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
