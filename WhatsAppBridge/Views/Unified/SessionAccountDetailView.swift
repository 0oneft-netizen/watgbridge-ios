import SwiftUI

struct SessionAccountDetailView: View {
    @State private var showDisconnectConfirmation = false
    @State private var isDisconnecting = false
    @State private var disconnectError: String?

    let account:
        SessionAccountDTO

    var body: some View {
        List {
            Section {
                SessionDetailCard(
                    account:
                        account
                )
            }

            Section(
                "Tools"
            ) {
                NavigationLink {
                    RenameSessionView(
                        accountID:
                            account.id,
                        currentName:
                            account.displayName
                            ?? "",
                        phone:
                            account.phone
                            ?? ""
                    )
                } label: {
                    Label(
                        "Rename Session",
                        systemImage:
                            "pencil"
                    )
                }

                NavigationLink {
                    SessionQuickReplyEditor(
                        accountID:
                            account.id,
                        sessionName:
                            account.displayName
                            ?? ""
                    )
                } label: {
                    Label(
                        "Quick Replies",
                        systemImage:
                            "bolt.fill"
                    )
                }
            }

            Section(
                "Connection"
            ) {
                SessionConnectionChip(
                    status:
                        account.status ?? ""
                )

                Text(
                    "Renaming this session does not change its routing identity."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button(role: .destructive) {
                    showDisconnectConfirmation = true
                } label: {
                    HStack {
                        if isDisconnecting {
                            ProgressView()
                        }

                        Text(
                            isDisconnecting
                            ? "Disconnecting…"
                            : "Disconnect Session"
                        )
                        .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .disabled(isDisconnecting)
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(.bar)
        }
.navigationTitle(
            (account.displayName ?? "").isEmpty
                ? ((account.phone ?? "").isEmpty ? "WhatsApp Account" : (account.phone ?? ""))
                : (account.displayName ?? "")
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }
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
                    isDisconnecting = true
                    disconnectError = nil

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

                    isDisconnecting = false
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Messages stay in the app. "
                + "Only this WhatsApp connection is disconnected."
            )
        }
        .alert(
            "Could Not Disconnect",
            isPresented: Binding(
                get: { disconnectError != nil },
                set: { value in
                    if !value {
                        disconnectError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(disconnectError ?? "")
        }

}
