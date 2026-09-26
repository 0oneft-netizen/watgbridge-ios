import SwiftUI

struct SessionDetailCard: View {
    let account:
        SessionAccountDTO

    var body: some View {
        VStack(
            alignment:
                .leading,
            spacing: 10
        ) {
            HStack {
                Image(
                    systemName:
                        AccountTypePresentation
                            .icon(
                                account
                                    .accountType
                            )
                )

                VStack(
                    alignment:
                        .leading,
                    spacing: 2
                ) {
                    Text(
                        account.displayName
                    )
                    .font(
                        .headline
                    )

                    Text(
                        AccountTypePresentation
                            .title(
                                account
                                    .accountType
                            )
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }

                Spacer()

                SessionHealthBadge(
                    level:
                        health
                )
            }

            if !account.phone.isEmpty {
                Text(
                    "+"
                    +
                    account.phone
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .padding(14)
        .background(
            Color.secondary
                .opacity(0.07),
            in:
                RoundedRectangle(
                    cornerRadius: 14
                )
        )
    }

    private var health:
        SessionHealthLevel {
        switch account.status
            .lowercased() {

        case "connected":
            return .healthy

        case "reconnect_required":
            return .attention

        case "disconnected":
            return .offline

        default:
            return .unknown
        }
    }
}
