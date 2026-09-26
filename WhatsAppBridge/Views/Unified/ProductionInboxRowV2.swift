import SwiftUI

struct ProductionInboxRowV2: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions =
        SessionDirectory.shared

    @ObservedObject
    private var local =
        ConversationLocalState.shared

    @ObservedObject
    private var workflow =
        CustomerWorkflowStore.shared

    @ObservedObject
    private var followUps =
        CustomerFollowUpStore.shared

    var body: some View {
        HStack(spacing: 12) {
            CustomerAvatarView(
                jid:
                    conversation.jid
            )
            .frame(
                width: 52,
                height: 52
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                HStack {
                    Text(customerTitle)
                        .font(
                            .headline
                        )
                        .lineLimit(1)

                    Spacer()

                    if let timestamp =
                        latestTimestamp {

                        CustomerRecencyBadge(
                            timestamp:
                                timestamp
                        )
                    }
                }

                HStack(spacing: 6) {
                    SessionRouteBadge(
                        name:
                            sessions.name(
                                for:
                                    conversation
                                        .accountID
                                    ?? "default"
                            )
                    )

                    if workflow
                        .value(
                            for:
                                conversation
                        )
                        .priority {

                        Image(
                            systemName:
                                "exclamationmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .orange
                        )
                    }

                    FollowUpBadge(
                        conversation:
                            conversation
                    )
                }

                if let draft =
                    ConversationDraftPreview
                        .text(
                            conversation
                        ) {

                    HStack(spacing: 4) {
                        Text("Draft")
                            .foregroundStyle(
                                .red
                            )
                            .fontWeight(
                                .semibold
                            )

                        Text(draft)
                            .foregroundStyle(
                                .secondary
                            )
                            .lineLimit(1)
                    }
                    .font(.subheadline)

                } else {
                    Text(previewText)
                        .font(.subheadline)
                        .foregroundStyle(
                            .secondary
                        )
                        .lineLimit(1)
                }
            }

            if local
                .isUnread(
                    conversation
                ) {

                Circle()
                    .frame(
                        width: 9,
                        height: 9
                    )
                    .foregroundStyle(
                        .green
                    )
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

    private var customerTitle:
        String {

        let candidates = [
            conversation.name,
            ChatIdentity
                .customerPhone(
                    from:
                        conversation.jid
                )
        ]

        return candidates
            .compactMap { $0 }
            .map {
                $0.trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            }
            .first {
                !$0.isEmpty
            }
            ?? "Customer"
    }

    private var previewText:
        String {

        if local
            .isArchived(
                conversation
            ) {
            return "Archived"
        }

        return conversation
            .lastMessage?
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .nonEmpty
            ?? "No messages yet"
    }

    private var latestTimestamp:
        Int64? {
        conversation.updatedAt
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
