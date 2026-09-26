import SwiftUI

struct SessionDetailCard: View {
    let account: SessionAccountDTO

    private var displayName: String {
        let value =
            (account.displayName ?? "")
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !value.isEmpty {
            return value
        }

        let phone =
            (account.phone ?? "")
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !phone.isEmpty {
            return phone.hasPrefix("+")
                ? phone
                : "+" + phone
        }

        return "WhatsApp Account"
    }

    private var phone: String {
        (account.phone ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            HStack {
                Image(
                    systemName:
                        AccountTypePresentation
                            .icon(
                                account.accountType
                            )
                )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text(displayName)
                        .font(.headline)

                    Text(
                        AccountTypePresentation
                            .title(
                                account.accountType
                            )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                SessionHealthBadge(
                    level: health
                )
            }

            if !phone.isEmpty {
                Text(
                    phone.hasPrefix("+")
                        ? phone
                        : "+" + phone
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            Color.secondary.opacity(0.07),
            in: RoundedRectangle(
                cornerRadius: 14
            )
        )
    }

    private var health: SessionHealthLevel {
        switch (account.status ?? "unknown")
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
