import SwiftUI

struct ProductionConversationRow: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    private var title: String {
        let value =
            conversation.name
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !value.isEmpty {
            return value
        }

        return customerPhone
    }

    private var customerPhone: String {
        let jid = conversation.jid

        if let at =
            jid.firstIndex(of: "@") {
            return String(
                jid[..<at]
            )
        }

        return jid
    }

    private var preview: String {
        let value =
            conversation.lastMessage
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        return value.isEmpty
            ? " "
            : value
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
                        "person.fill"
                )
                .font(.title2)
                .foregroundStyle(
                    .secondary
                )
            }
            .frame(
                width: 52,
                height: 52
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(
                            .body.weight(
                                .semibold
                            )
                        )
                        .lineLimit(1)

                    Spacer()

                    if conversation.unread > 0 {
                        Text(
                            "\(conversation.unread)"
                        )
                        .font(
                            .caption2.bold()
                        )
                        .foregroundStyle(
                            .white
                        )
                        .padding(
                            .horizontal,
                            7
                        )
                        .padding(
                            .vertical,
                            3
                        )
                        .background(
                            Color.green,
                            in: Capsule()
                        )
                    }
                }

                CustomerSessionLine(
                    customerPhone:
                        customerPhone,
                    accountID:
                        conversation.accountID
                )

                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                    .lineLimit(1)
            }
        }
        .padding(
            .vertical,
            5
        )
        .contentShape(
            Rectangle()
        )
    }
}
