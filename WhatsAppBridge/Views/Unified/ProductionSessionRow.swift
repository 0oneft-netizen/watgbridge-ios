import SwiftUI

struct ProductionSessionRow: View {
    let account:
        SessionAccountDTO

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        Color.secondary
                            .opacity(0.10)
                    )

                Image(
                    systemName:
                        AccountTypePresentation
                            .icon(
                                account
                                    .accountType
                            )
                )
            }
            .frame(
                width: 46,
                height: 46
            )

            VStack(
                alignment:
                    .leading,
                spacing: 4
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

                if !account.phone.isEmpty {
                    Text(
                        "+"
                        +
                        account.phone
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            Spacer()

            SessionHealthBadge(
                level:
                    health
            )
        }
        .padding(
            .vertical,
            4
        )
    }

    private var health:
        SessionHealthLevel {

        switch account.status
            .lowercased() {

        case "connected":
            return .healthy

        case "disconnected":
            return .offline

        case "reconnect_required":
            return .attention

        default:
            return .unknown
        }
    }
}
