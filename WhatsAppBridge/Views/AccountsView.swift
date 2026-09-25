import SwiftUI

struct AccountsView: View {
    @State private var accounts:
        [WhatsAppAccount] = []

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(accounts) { account in
                        HStack(spacing: 12) {

                            ZStack {
                                Circle()
                                    .fill(
                                        Color.secondary
                                            .opacity(0.15)
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
                                        .isEmpty
                                    ? "WhatsApp Account"
                                    : account.displayName
                                )
                                .font(.headline)

                                Text(
                                    account.phone
                                        .isEmpty
                                    ? account.id
                                    : account.phone
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }

                            Spacer()

                            VStack(
                                alignment: .trailing
                            ) {
                                Circle()
                                    .fill(
                                        account.status ==
                                        "connected"
                                        ? Color.green
                                        : Color.secondary
                                    )
                                    .frame(
                                        width: 9,
                                        height: 9
                                    )

                                if account.isPrimary {
                                    Text("Primary")
                                        .font(.caption2)
                                        .foregroundStyle(
                                            .secondary
                                        )
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingAdd = true
                    } label: {
                        Label(
                            "Link another WhatsApp",
                            systemImage: "qrcode"
                        )
                    }
                }
            }
            .navigationTitle("WhatsApp Accounts")
            .task {
                await load()
            }
            .refreshable {
                await load()
            }
            .sheet(
                isPresented: $showingAdd
            ) {
                LinkWhatsAppView()
            }
        }
    }

    @MainActor
    private func load() async {
        accounts =
            (try? await
                AccountsAPI.shared.accounts()
            ) ?? []
    }
}
