import SwiftUI

struct SessionRouteCard: View {
    let session: SessionIdentity

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        AppVisualDesign
                            .accent
                            .opacity(0.12)
                    )

                Image(
                    systemName:
                        (session.accountType ?? "")
                            .lowercased()
                            == "business"
                        ? "briefcase.fill"
                        : "message.fill"
                )
                .foregroundStyle(
                    AppVisualDesign.accent
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
                    session.effectiveName
                )
                .font(
                    .body.weight(
                        .semibold
                    )
                )

                Text(
                    session.accountTypeLabel
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                if !session.formattedPhone.isEmpty {
                    Text(
                        session.formattedPhone
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }

            Spacer()

            AppStatusBadge(
                status:
                    session.status
            )
        }
        .padding(.vertical, 5)
    }
}
