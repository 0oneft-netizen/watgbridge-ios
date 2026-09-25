import SwiftUI

struct AccountPickerView: View {
    @Environment(\.dismiss)
    private var dismiss

    @State private var accounts:
        [WhatsAppAccount] = []

    let onSelect:
        (WhatsAppAccount) -> Void

    var body: some View {
        NavigationStack {
            List(accounts) { account in
                Button {
                    Haptics.selection()
                    onSelect(account)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    Color.secondary
                                        .opacity(0.12)
                                )

                            Image(
                                systemName:
                                    "message.fill"
                            )
                        }
                        .frame(
                            width: 44,
                            height: 44
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
                            .foregroundStyle(
                                .primary
                            )

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

                        if account.status ==
                            "connected"
                        {
                            Image(
                                systemName:
                                    "checkmark.circle.fill"
                            )
                            .foregroundStyle(
                                .green
                            )
                        }
                    }
                }
            }
            .navigationTitle(
                "Send From"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .task {
                accounts =
                    (try? await
                        AccountsAPI.shared
                            .accounts()
                    ) ?? []
            }
        }
    }
}
