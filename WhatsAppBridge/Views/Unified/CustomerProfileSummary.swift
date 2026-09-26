import SwiftUI

struct CustomerProfileSummary: View {
    let conversation:
        Conversation

    let messages:
        [Message]

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    var body: some View {
        VStack(spacing: 12) {
            CustomerAvatarView(
                jid:
                    conversation.jid
            )
            .frame(
                width: 108,
                height: 108
            )

            Text(customerName)
                .font(
                    .title2.bold()
                )

            if !customerPhone.isEmpty {
                Text(customerPhone)
                    .foregroundStyle(
                        .secondary
                    )
            }

            SessionRouteBadge(
                name:
                    sessions.name(
                        for:
                            conversation
                                .accountID
                            ?? "default"
                    )
            )

            HStack {
                metric(
                    ProfileMediaFilter
                        .media(
                            messages
                        )
                        .count,
                    "Media"
                )

                metric(
                    ProfileMediaFilter
                        .documents(
                            messages
                        )
                        .count,
                    "Docs"
                )

                metric(
                    MessageLinkExtractor
                        .links(
                            in:
                                messages
                        )
                        .count,
                    "Links"
                )
            }
        }
        .frame(
            maxWidth:
                .infinity
        )
        .padding(
            .vertical,
            18
        )
    }

    private var customerName: String {
        let name = conversation.name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return name.isEmpty
            ? customerPhone
            : name
    }

    private var customerPhone:
        String {
        ChatIdentity
            .customerPhone(
                from:
                    conversation.jid
            )
    }

    private func metric(
        _ value: Int,
        _ title: String
    ) -> some View {

        VStack(spacing: 2) {
            Text("\(value)")
                .font(
                    .headline
                )

            Text(title)
                .font(
                    .caption
                )
                .foregroundStyle(
                    .secondary
                )
        }
        .frame(
            maxWidth:
                .infinity
        )
    }
}
