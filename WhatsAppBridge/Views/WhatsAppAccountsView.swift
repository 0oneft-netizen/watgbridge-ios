import SwiftUI

struct WhatsAppAccountsView: View {
    @State private var accounts: [WhatsAppAccount] = []
    @State private var showingAddAccount = false

    var body: some View {
        NavigationStack {
            List {
                if accounts.isEmpty {
                    ContentUnavailableView(
                        "No WhatsApp Accounts",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text(
                            "Connect WhatsApp or WhatsApp Business."
                        )
                    )
                } else {
                    ForEach(accounts) { account in
                        WhatsAppAccountRow(
                            account: account
                        )
                    }
                }

                Section {
                    Button {
                        showingAddAccount = true
                    } label: {
                        Label(
                            "Connect another WhatsApp",
                            systemImage: "qrcode"
                        )
                    }
                }
            }
            .navigationTitle("WhatsApp Accounts")
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button {
                        showingAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(
                isPresented: $showingAddAccount
            ) {
                WhatsAppTypePickerView()
            }
            .task {
                await load()
            }
            .refreshable {
                await load()
            }
        }
    }

    @MainActor
    private func load() async {
        do {
            accounts =
                try await AccountAPI.shared
                    .accounts()
        } catch {
            print(
                "Account load error:",
                error
            )
        }
    }
}

private struct WhatsAppAccountRow: View {
    let account: WhatsAppAccount

    private var connected: Bool {
        account.status == "connected"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        Color.secondary
                            .opacity(0.12)
                    )

                Image(
                    systemName: "phone.fill"
                )
                .foregroundStyle(
                    connected
                    ? Color.green
                    : Color.secondary
                )
            }
            .frame(
                width: 46,
                height: 46
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(
                    account.displayName.isEmpty
                    ? "WhatsApp Account"
                    : account.displayName
                )
                .font(.headline)

                if !account.phone.isEmpty {
                    Text(account.phone)
                        .font(.caption)
                        .foregroundStyle(
                            Color.secondary
                        )
                }

                Text(account.status)
                    .font(.caption2)
                    .foregroundStyle(
                        connected
                        ? Color.green
                        : Color.secondary
                    )
            }

            Spacer()

            if account.isPrimary {
                Text("PRIMARY")
                    .font(.caption2.bold())
                    .foregroundStyle(
                        Color.secondary
                    )
            }

            Image(
                systemName:
                    connected
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .foregroundStyle(
                connected
                ? Color.green
                : Color.secondary
            )
        }
        .padding(.vertical, 4)
    }
}
