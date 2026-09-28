import SwiftUI

struct SessionAccountDetailView: View {
    let account: SessionAccountDTO

    @State private var showDisconnectConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var isDisconnecting = false
    @State private var isDeleting = false
    @State private var operationError: String?

    private var displayTitle: String {
        let name = (account.displayName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !name.isEmpty {
            return name
        }

        let phone = (account.phone ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return phone.isEmpty
            ? "WhatsApp Account"
            : phone
    }

    private var isDisconnected: Bool {
        (account.status ?? "").lowercased() == "disconnected"
    }

    private var canDelete: Bool {
        account.id != "default" && !isDeleting
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: {
                operationError != nil
            },
            set: { presented in
                if !presented {
                    operationError = nil
                }
            }
        )
    }

    var body: some View {
        List {
            identitySection
            toolsSection
            connectionSection
            disconnectSection
            deleteSection
        }
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Disconnect this session?",
            isPresented: $showDisconnectConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Disconnect",
                role: .destructive
            ) {
                Task {
                    await disconnect()
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}
        } message: {
            Text(
                "The WhatsApp connection will be disconnected. Existing message history will remain available."
            )
        }
        .confirmationDialog(
            "Delete this session permanently?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Delete Session and Local History",
                role: .destructive
            ) {
                Task {
                    await deleteSession()
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}
        } message: {
            Text(
                "This removes only this session and its local history from the app. Other WhatsApp sessions are not affected."
            )
        }
        .alert(
            "Session Operation Failed",
            isPresented: errorPresented
        ) {
            Button(
                "OK",
                role: .cancel
            ) {}
        } message: {
            Text(operationError ?? "")
        }
    }

    private var identitySection: some View {
        Section {
            SessionDetailCard(
                account: account
            )
        }
    }

    private var toolsSection: some View {
        Section("Tools") {
            NavigationLink {
                RenameSessionView(
                    accountID: account.id,
                    currentName: account.displayName ?? "",
                    phone: account.phone ?? ""
                )
            } label: {
                Label(
                    "Rename Session",
                    systemImage: "pencil"
                )
            }

            NavigationLink {
                SessionQuickReplyEditor(
                    accountID: account.id,
                    sessionName: account.displayName ?? ""
                )
            } label: {
                Label(
                    "Quick Replies",
                    systemImage: "bolt.fill"
                )
            }
        }
    }

    private var connectionSection: some View {
        Section("Connection") {
            SessionConnectionChip(
                status: account.status ?? ""
            )

            Text(
                "Renaming this session does not change its routing identity."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var disconnectSection: some View {
        Section {
            Button(
                role: .destructive
            ) {
                showDisconnectConfirmation = true
            } label: {
                HStack {
                    Spacer()

                    if isDisconnecting {
                        ProgressView()
                            .padding(.trailing, 4)
                    }

                    Label(
                        isDisconnecting
                            ? "Disconnecting…"
                            : "Disconnect Session",
                        systemImage:
                            "rectangle.portrait.and.arrow.right"
                    )
                    .fontWeight(.semibold)

                    Spacer()
                }
            }
            .disabled(
                isDisconnecting || isDisconnected
            )
        } footer: {
            Text(
                "Disconnecting keeps this session's existing message history and routing identity."
            )
        }
    }

    private var deleteSection: some View {
        Section {
            Button(
                role: .destructive
            ) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()

                    if isDeleting {
                        ProgressView()
                            .padding(.trailing, 4)
                    }

                    Label(
                        isDeleting
                            ? "Deleting…"
                            : "Delete Session",
                        systemImage: "trash"
                    )
                    .fontWeight(.semibold)

                    Spacer()
                }
            }
            .disabled(!canDelete)
        } footer: {
            if account.id == "default" {
                Text(
                    "The primary legacy session cannot be deleted here."
                )
            } else {
                Text(
                    "Deletes this WhatsApp session and its local chat history. Other sessions are not affected."
                )
            }
        }
    }

    @MainActor
    private func disconnect() async {
        guard !isDisconnecting else {
            return
        }

        isDisconnecting = true
        operationError = nil

        defer {
            isDisconnecting = false
        }

        do {
            try await APIClient.shared.disconnectSession(
                accountID: account.id
            )

            await SessionDirectory.shared.refresh()
        } catch {
            operationError = error.localizedDescription
        }
    }

    @MainActor
    private func deleteSession() async {
        guard canDelete else {
            return
        }

        isDeleting = true
        operationError = nil

        defer {
            isDeleting = false
        }

        do {
            try await APIClient.shared.deleteSession(
                accountID: account.id,
                deleteHistory: true
            )

            await SessionDirectory.shared.refresh()
        } catch {
            operationError = error.localizedDescription
        }
    }
}
