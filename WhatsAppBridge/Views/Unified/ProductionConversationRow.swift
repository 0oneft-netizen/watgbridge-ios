import SwiftUI

struct ProductionConversationRow: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions = SessionDirectory.shared

    private var title: String {
        ChatIdentity.customerName(
            conversation: conversation
        )
    }

    private var sessionName: String {
        sessions.name(
            for: conversation.accountID
        )
    }

    private var preview: String {
        conversation.previewText
    }

    private var hasUnread: Bool {
        conversation.unread > 0
    }

    var body: some View {
        HStack(
            alignment: .center,
            spacing: 12
        ) {
            avatar

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 6
                ) {
                    Text(title)
                        .font(
                            .system(
                                size: 17,
                                weight:
                                    hasUnread
                                    ? .semibold
                                    : .medium
                            )
                        )
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    if conversation.lastMessageAt > 0 {
                        Text(timeText)
                            .font(
                                .system(
                                    size: 12,
                                    weight:
                                        hasUnread
                                        ? .medium
                                        : .regular
                                )
                            )
                            .foregroundStyle(
                                hasUnread
                                ? AppVisualDesign.accent
                                : Color.secondary
                            )
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 5) {
                    SessionMiniBadge(
                        name: sessionName
                    )

                    if conversation.pinned == true {
                        Image(
                            systemName: "pin.fill"
                        )
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    }

                    if conversation.muted == true {
                        Image(
                            systemName:
                                "speaker.slash.fill"
                        )
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }

                HStack(
                    alignment: .center,
                    spacing: 6
                ) {
                    Text(preview)
                        .font(
                            .system(
                                size: 15,
                                weight:
                                    hasUnread
                                    ? .medium
                                    : .regular
                            )
                        )
                        .foregroundStyle(
                            hasUnread
                            ? Color.primary.opacity(0.82)
                            : Color.secondary
                        )
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    UnreadBadge(
                        count: conversation.unread
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(
            .vertical,
            12
        )
        .contentShape(Rectangle())
        .task {
            if sessions.sessions.isEmpty {
                await sessions.refresh()
            }
        }
    }

    private var avatar: some View {
        AsyncImage(
            url: APIClient.shared.avatarURL(
                for: conversation.jid
            )
        ) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()

            default:
                AppAvatarPlaceholder(
                    initials: conversation.initials
                )
            }
        }
        .frame(
            width: 52,
            height: 52
        )
        .clipShape(Circle())
        .overlay(Circle().stroke(WhatsAppVisualDesign.border, lineWidth: 1))
    }

    private var timeText: String {
        var raw = conversation.lastMessageAt

        if raw > 10_000_000_000 {
            raw /= 1000
        }

        let date = Date(
            timeIntervalSince1970:
                TimeInterval(raw)
        )

        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return date.formatted(
                date: .omitted,
                time: .shortened
            )
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let days =
            calendar.dateComponents(
                [.day],
                from:
                    calendar.startOfDay(
                        for: date
                    ),
                to:
                    calendar.startOfDay(
                        for: Date()
                    )
            ).day ?? 999

        if days < 7 {
            return date.formatted(
                .dateTime.weekday(.abbreviated)
            )
        }

        return date.formatted(
            .dateTime
                .day()
                .month(.twoDigits)
        )
    }
}
