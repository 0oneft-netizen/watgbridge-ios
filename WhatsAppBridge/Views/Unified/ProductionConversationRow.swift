import SwiftUI

struct ProductionConversationRow: View {
    let conversation: Conversation

    @ObservedObject
    private var sessions = SessionDirectory.shared

    private var title: String {
        let value = conversation.name
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return value.isEmpty
            ? customerPhone
            : value
    }

    private var customerPhone: String {
        ChatIdentity.customerPhone(
            from: conversation.jid
        )
    }

    private var sessionName: String {
        sessions.name(
            for: conversation.accountID
        )
    }

    private var preview: String {
        let value = conversation.lastMessage
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return value.isEmpty
            ? "No messages yet"
            : value
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
                spacing: 3
            ) {
                topLine

                sessionLine

                bottomLine
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .task {
            if sessions.sessions.isEmpty {
                await sessions.refresh()
            }
        }
    }

    // MARK: - Avatar

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
                avatarFallback
            }
        }
        .frame(
            width: 54,
            height: 54
        )
        .clipShape(Circle())
    }

    private var avatarFallback: some View {
        ZStack {
            Circle()
                .fill(
                    Color.secondary
                        .opacity(0.14)
                )

            Text(conversation.initials)
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Top

    private var topLine: some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: 6
        ) {
            Text(title)
                .font(
                    .system(
                        size: 16.5,
                        weight:
                            hasUnread
                            ? .semibold
                            : .medium
                    )
                )
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            if conversation.lastMessageAt > 0 {
                Text(timeText)
                    .font(
                        .system(
                            size: 12.5,
                            weight:
                                hasUnread
                                ? .medium
                                : .regular
                        )
                    )
                    .foregroundStyle(
                        hasUnread
                        ? ChatDesign.accent
                        : Color.secondary
                    )
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Session

    private var sessionLine: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(ChatDesign.accent)
                .frame(
                    width: 6,
                    height: 6
                )

            Text(sessionName)
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    ChatDesign.accent
                )
                .lineLimit(1)

            if conversation.pinned == true {
                Image(
                    systemName: "pin.fill"
                )
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }

            if conversation.muted == true {
                Image(
                    systemName:
                        "speaker.slash.fill"
                )
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Preview

    private var bottomLine: some View {
        HStack(
            alignment: .center,
            spacing: 6
        ) {
            Text(preview)
                .font(
                    .system(
                        size: 14.5,
                        weight:
                            hasUnread
                            ? .medium
                            : .regular
                    )
                )
                .foregroundStyle(
                    hasUnread
                    ? Color.primary.opacity(0.78)
                    : Color.secondary
                )
                .lineLimit(1)

            Spacer(minLength: 8)

            UnreadBadge(
                count: conversation.unread
            )
        }
    }

    // MARK: - Time

    private var timeText: String {
        let date = Date(
            timeIntervalSince1970:
                TimeInterval(
                    conversation.lastMessageAt
                )
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

        let start = calendar.startOfDay(
            for: date
        )

        let now = calendar.startOfDay(
            for: Date()
        )

        let days = calendar.dateComponents(
            [.day],
            from: start,
            to: now
        ).day ?? 999

        if days < 7 {
            return date.formatted(
                .dateTime
                    .weekday(.abbreviated)
            )
        }

        return date.formatted(
            .dateTime
                .day()
                .month(.twoDigits)
        )
    }
}
