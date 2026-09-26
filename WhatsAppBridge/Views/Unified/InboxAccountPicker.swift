import SwiftUI

struct InboxAccountPicker: View {
    @Binding var accountID: String?
    @ObservedObject var sessions: SessionDirectory

    var body: some View {
        Menu {
            Button {
                accountID = nil
            } label: {
                Label(
                    "כל החשבונות",
                    systemImage: accountID == nil
                        ? "checkmark.circle.fill"
                        : "circle"
                )
            }

            Divider()

            ForEach(
                Array(sessions.accounts.enumerated()),
                id: \.offset
            ) { _, account in
                let resolvedID = account.id

                Button {
                    accountID = resolvedID
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(
                                account.displayName
                                ?? resolvedID
                            )

                            if let phone = account.phone,
                               !phone.isEmpty {
                                Text(phone)
                                    .font(.caption)
                            }
                        }

                        if accountID == resolvedID {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label(
                selectedTitle,
                systemImage: "person.2.circle"
            )
        }
    }

    private var selectedTitle: String {
        guard let accountID else {
            return "כל החשבונות"
        }

        if let account = sessions.accounts.first(
            where: { $0.id == accountID }
        ) {
            return account.displayName ?? accountID
        }

        return accountID
    }
}
