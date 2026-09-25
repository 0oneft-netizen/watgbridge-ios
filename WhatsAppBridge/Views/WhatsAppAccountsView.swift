import SwiftUI

struct WhatsAppAccountsView: View {
    @State private var accounts:
        [WhatsAppAccountStatus] = []

    @State private var showingPairing = false

    var body: some View {
        NavigationStack {
            List {
                if accounts.isEmpty {
                    ContentUnavailableView(
                        "No WhatsApp Accounts",
                        systemImage:
                            "rectangle.stack.badge.plus",
                        description: Text(
                            "Link a WhatsApp account to start."
                        )
                    )
                } else {
                    ForEach(
                        Array(accounts.enumerated()),
                        id: \.offset
                    ) { _, account in
                        WhatsAppAccountRow(
                            account: account
                        )
                    }
                }

                Section {
                    Button {
                        showingPairing = true
                    } label: {
                        Label(
                            "Link WhatsApp Account",
                            systemImage: "qrcode"
                        )
                    }
                }
            }
            .navigationTitle(
                "WhatsApp Accounts"
            )
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button {
                        showingPairing = true
                    } label: {
                        Image(
                            systemName: "plus"
                        )
                    }
                }
            }
            .sheet(
                isPresented: $showingPairing
            ) {
                WhatsAppPairingView()
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
                "Accounts load error:",
                error
            )
        }
    }
}

private struct WhatsAppAccountRow: View {
    let account:
        WhatsAppAccountStatus

    private var name: String {
        if let displayName =
            account.displayName,
           !displayName.isEmpty
        {
            return displayName
        }

        return "WhatsApp Account"
    }

    private var phone: String {
        account.phone ?? ""
    }

    private var statusText: String {
        account.status
    }

    private var isConnected: Bool {
        if let connected =
            account.connected
        {
            return connected
        }

        return account.status ==
            "connected"
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
                    systemName:
                        "phone.fill"
                )
                .foregroundStyle(
                    isConnected
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
                Text(name)
                    .font(.headline)

                if !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(
                            Color.secondary
                        )
                }

                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(
                        isConnected
                        ? Color.green
                        : Color.secondary
                    )
            }

            Spacer()

            Image(
                systemName:
                    isConnected
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .foregroundStyle(
                isConnected
                ? Color.green
                : Color.secondary
            )
        }
        .padding(
            .vertical,
            4
        )
    }
}
