import SwiftUI

struct ActiveSessionsContent: View {
    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    @StateObject
    private var live =
        SessionLiveStatusCoordinator()

    @State
    private var pendingDelete:
        SessionAccountDTO?

    @State
    private var deleteError:
        String?

    @State
    private var isDeleting = false

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
                    sessionRow(account)
                }
            } header: {
                Text("WhatsApp Accounts")
            } footer: {
                Text(
                    "Tap an account for details. Swipe left on a secondary account to delete it."
                )
            }
        }
        .confirmationDialog(
            "Delete this session?",
            isPresented:
                deleteConfirmationBinding,
            titleVisibility: .visible
        ) {
            if let account = pendingDelete,
               account.id != "default" {

                Button(
                    "Delete Session and Local History",
                    role: .destructive
                ) {
                    Task {
                        await deleteSession(
                            account
                        )
                    }
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
                pendingDelete = nil
            }
        } message: {
            if let account = pendingDelete {
                Text(
                    deleteMessage(
                        for: account
                    )
                )
            }
        }
        .alert(
            "Could Not Delete Session",
            isPresented:
                deleteErrorBinding
        ) {
            Button(
                "OK",
                role: .cancel
            ) {
                deleteError = nil
            }
        } message: {
            Text(deleteError ?? "")
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

    @ViewBuilder
    private func sessionRow(
        _ account: SessionAccountDTO
    ) -> some View {

        NavigationLink {
            SessionAccountDetailView(
                account: account
            )
        } label: {
            ProductionSessionRow(
                account: account
            )
        }
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: false
        ) {
            if account.id != "default" {
                Button(
                    role: .destructive
                ) {
                    pendingDelete =
                        account
                } label: {
                    Label(
                        "Delete",
                        systemImage: "trash"
                    )
                }
            }
        }
        .contextMenu {
            if account.id != "default" {
                Button(
                    role: .destructive
                ) {
                    pendingDelete =
                        account
                } label: {
                    Label(
                        "Delete Session…",
                        systemImage: "trash"
                    )
                }
            }

            Text(
                account.status ??
                "Unknown status"
            )
        }
    }

    private var deleteConfirmationBinding:
        Binding<Bool> {

        Binding(
            get: {
                pendingDelete != nil
            },
            set: { presented in
                if !presented &&
                   !isDeleting {
                    pendingDelete = nil
                }
            }
        )
    }

    private var deleteErrorBinding:
        Binding<Bool> {

        Binding(
            get: {
                deleteError != nil
            },
            set: { presented in
                if !presented {
                    deleteError = nil
                }
            }
        )
    }

    private func deleteMessage(
        for account: SessionAccountDTO
    ) -> String {

        let name =
            (account.displayName ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let visibleName =
            name.isEmpty
            ? account.id
            : name

        return
            "This removes \(visibleName) and its local history from this app. Other WhatsApp sessions are not affected."
    }

    @MainActor
    private func deleteSession(
        _ account: SessionAccountDTO
    ) async {

        guard
            account.id != "default",
            !isDeleting
        else {
            return
        }

        isDeleting = true
        deleteError = nil

        defer {
            isDeleting = false
        }

        do {
            try await APIClient.shared
                .deleteSession(
                    accountID:
                        account.id,
                    deleteHistory:
                        true
                )

            pendingDelete = nil

            await sessions.refresh()

        } catch {
            deleteError =
                error.localizedDescription
        }
    }
}
