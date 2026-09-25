import SwiftUI

struct WhatsAppAccountsView: View {
    @State private var accounts:
        [WhatsAppAccount] = []

    @State private var pairingID:
        String?

    var body: some View {
        List {
            Section {
                Button {
                    Task {
                        await addAccount()
                    }
                } label: {
                    Label(
                        "Link WhatsApp Account",
                        systemImage: "qrcode"
                    )
                }
            }

            Section("Connected Accounts") {
                if accounts.isEmpty {
                    ContentUnavailableView(
                        "No WhatsApp Accounts",
                        systemImage:
                            "message.badge",
                        description: Text(
                            "Link a WhatsApp account using QR."
                        )
                    )
                }

                ForEach(accounts) {
                    account in

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
                        }
                        .frame(
                            width: 46,
                            height: 46
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {
                            Text(
                                account.displayName
                            )
                            .font(.headline)

                            if !account.phone.isEmpty {
                                Text(account.phone)
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                            }

                            Text(account.status)
                                .font(.caption2)
                                .foregroundStyle(
                                    account.connected
                                    ? Color.green
                                    : Color.secondary
                                )
                        }

                        Spacer()

                        Circle()
                            .fill(
                                account.connected
                                ? Color.green
                                : Color.orange
                            )
                            .frame(
                                width: 9,
                                height: 9
                            )
                    }
                }
            }
        }
        .navigationTitle(
            "WhatsApp Accounts"
        )
        .task {
            await load()
        }
        .sheet(
            item: Binding(
                get: {
                    pairingID.map {
                        PairingIdentifier(
                            id: $0
                        )
                    }
                },
                set: {
                    pairingID =
                        $0?.id
                }
            )
        ) { item in
            WhatsAppPairingView(
                accountID: item.id
            )
        }
    }

    @MainActor
    private func load() async {
        accounts =
            (try? await
                AccountAPI.shared.accounts()
            ) ?? []
    }

    @MainActor
    private func addAccount() async {
        do {
            let id =
                try await AccountAPI.shared
                    .createAccount()

            pairingID = id

            await load()

        } catch {
            Haptics.error()
        }
    }
}

private struct PairingIdentifier:
    Identifiable
{
    let id: String
}
