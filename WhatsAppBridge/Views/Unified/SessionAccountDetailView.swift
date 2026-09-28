import SwiftUI

struct SessionAccountDetailView: View {
    let account: SessionAccountDTO

    @Environment(\.dismiss) private var dismiss

    @State private var showDisconnectConfirmation = false
    @State private var showDeleteConfirmation = false

    @State private var isDisconnecting = false
    @State private var isDeleting = false

    @State private var disconnectError: String?
    @State private var deleteError: String?

    private var displayName: String {
        let name = (account.displayName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !name.isEmpty {
            return name
        }

        let phone = (account.phone ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return phone.isEmpty ? "WhatsApp Account" : phone
    }

    private var status: String {
        account.status ?? ""
    }

    private var isDisconnected: Bool {
        status.lowercased() == "disconnected"
    }

    private var isPrimary: Bool {
        account.id == "default"
    }

    private var deleteFooter: String {
        if isPrimary {
            return "The primary legacy session cannot be deleted here."
        }

        return "Deletes only this WhatsApp session and its local chat history. Other sessions are not affected."
    }

    var body: some View {
        List {
            accountSection
            toolsSection
            connectionSection
            disconnectSection
            deleteSection
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if account.id != "default" {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    HStack {
                        Spacer()

                        Image(systemName: "trash")

                        Text("Delete Session")
                            .fontWeight(.semibold)

                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.horizontal)
                .padding(.top, 6)
                .padding(.bottom, 4)
                .background(.ultraThinMaterial)
                .disabled(isDeleting)
            }
        }
        .confirmationDialog(
            "Disconnect this session?",
            isPresented: $showDisconnectConfirmation,
            titleVisibility: .visible
        ) {
            Button("Disconnect", role: .destructive) {
                Task {
                    await disconnect()
                }
            }

            Button("Cancel", role: .cancel) {}
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

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This removes only this session and its local history from the app. Other WhatsApp sessions are not affected."
            )
        }
        .alert(
            "Could Not Disconnect",
            isPresented: disconnectErrorBinding
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(disconnectError ?? "")
        }
        .alert(
            "Could Not Delete Session",
            isPresented: deleteErrorBinding
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteError ?? "")
        }
    }

    private var accountSection: some View {
        Section {
            SessionDetailCard(account: account)
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
            SessionConnectionChip(status: status)

            Text(
                "Renaming this session does not change its routing identity."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var disconnectSection: some View {
        Section {
            Button(role: .destructive) {
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
                isDisconnecting ||
                isDeleting ||
                isDisconnected
            )
        } footer: {
            Text(
                "Disconnecting keeps this session's existing message history and routing identity."
            )
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
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
            .disabled(
                isDeleting ||
                isDisconnecting ||
                isPrimary
            )
        } footer: {
            Text(deleteFooter)
        }
    }

    private var disconnectErrorBinding: Binding<Bool> {
        Binding(
            get: {
                disconnectError != nil
            },
            set: { presented in
                if !presented {
                    disconnectError = nil
                }
            }
        )
    }

    private var deleteErrorBinding: Binding<Bool> {
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

    @MainActor
    private func disconnect() async {
        guard !isDisconnecting else {
            return
        }

        isDisconnecting = true
        disconnectError = nil

        defer {
            isDisconnecting = false
        }

        do {
            try await APIClient.shared.disconnectSession(
                accountID: account.id
            )

            await SessionDirectory.shared.refresh()
        } catch {
            disconnectError = error.localizedDescription
        }
    }

    @MainActor
    private func deleteSession() async {
        guard !isDeleting, !isPrimary else {
            return
        }

        isDeleting = true
        deleteError = nil

        defer {
            isDeleting = false
        }

        do {
            try await APIClient.shared.deleteSession(
                accountID: account.id,
                deleteHistory: true
            )

            await SessionDirectory.shared.refresh()
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}
