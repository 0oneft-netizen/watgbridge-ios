import SwiftUI

struct SessionAccountDetailView: View {
    @State private var showDisconnectConfirmation = false
    @State private var isDisconnecting = false
    @State private var disconnectError: String?
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?

    let account: SessionAccountDTO

    var body: some View {
        List {
            Section {
                SessionDetailCard(
                    account: account
                )
            }

            Section("Tools") {
                NavigationLink {
                    RenameSessionView(
                        accountID: account.id,
                        currentName:
                            account.displayName ?? "",
                        phone:
                            account.phone ?? ""
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
                        sessionName:
                            account.displayName ?? ""
                    )
                } label: {
                    Label(
                        "Quick Replies",
                        systemImage: "bolt.fill"
                    )
                }
            }

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
                    isDisconnecting
                    || account.status?.lowercased()
                        == "disconnected"
                )
            }

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
                    isDeleting
                    || account.id == "default"
                )
            } footer: {
                Text(
                    account.id == "default"
                    ? "The primary legacy session cannot be deleted here."
                    : "Deletes this WhatsApp session and its local chat history. Other sessions are not affected."
                )
            }
 footer: {
                Text(
                    "Disconnecting keeps this session's existing "
                    + "message history and routing identity."
                )
            }
        }
        .navigationTitle(
            (account.displayName ?? "").isEmpty
                ? (
                    (account.phone ?? "").isEmpty
                        ? "WhatsApp Account"
                        : (account.phone ?? "")
                )
                : (account.displayName ?? "")
        )
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Disconnect this session?",
            isPresented:
                $showDisconnectConfirmation,
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
                "The WhatsApp connection will be disconnected. "
                + "Existing message history will remain available."
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
                "This removes only this session and its local history from the app. It does not delete another connected WhatsApp session."
            )
        }
        .alert(
            "Could Not Disconnect",
            isPresented:
                disconnectErrorBinding
        ) {
            Button(
                "OK",
                role: .cancel
            ) {}
        } message: {
            Text(disconnectError ?? "")
        }
    }

    private var disconnectErrorBinding:
        Binding<Bool>
    {
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
            try await APIClient.shared
                .disconnectSession(
                    accountID: account.id
                )

            await SessionDirectory.shared
                .refresh()
        } catch {
            disconnectError =
                error.localizedDescription
        }
    }

    @MainActor
    private func deleteSession() async {
        guard !isDeleting,
              account.id != "default"
        else {
            return
        }

        isDeleting = true
        disconnectError = nil

        defer {
            isDeleting = false
        }

        do {
            try await APIClient.shared
                .deleteSession(
                    accountID: account.id,
                    deleteHistory: true
                )

            await SessionDirectory.shared
                .refresh()
        } catch {
            disconnectError =
                error.localizedDescription
        }
    }

}
