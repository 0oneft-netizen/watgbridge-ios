import SwiftUI

struct SessionAccountDetailView: View {
    @State private var showDisconnectConfirmation = false
    @State private var isDisconnecting = false
    @State private var disconnectError: String?

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
            } footer: {
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
}
