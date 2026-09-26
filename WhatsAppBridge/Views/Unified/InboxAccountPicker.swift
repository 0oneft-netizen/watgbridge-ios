import SwiftUI

struct InboxAccountPicker: View {
    @Binding
    var accountID:
        String?

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    var body: some View {
        Menu {
            Button {
                accountID = nil
            } label: {
                if accountID == nil {
                    Label(
                        "All Accounts",
                        systemImage:
                            "checkmark"
                    )
                } else {
                    Text(
                        "All Accounts"
                    )
                }
            }

            Divider()

            ForEach(
                sessions.accounts
            ) { account in

                Button {
                    accountID =
                        account.id
                } label: {
                    if accountID ==
                        account.id {

                        Label(
                            account
                                .displayName,
                            systemImage:
                                "checkmark"
                        )
                    } else {
                        Text(
                            account
                                .displayName
                        )
                    }
                }
            }
        } label: {
            Label(
                selectedName,
                systemImage:
                    "rectangle.stack"
            )
        }
    }

    private var selectedName:
        String {
        guard
            let accountID
        else {
            return "All Accounts"
        }

        return sessions.name(
            for:
                accountID
        )
    }
}
