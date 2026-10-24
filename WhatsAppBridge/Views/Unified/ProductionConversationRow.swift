import SwiftUI

struct ProductionConversationRow: View {
    let conversation: Conversation
    @ObservedObject private var customerCRM = CustomerCRMDirectory.shared
    @ObservedObject private var sessions = SessionDirectory.shared
    @ObservedObject private var drafts = ChatDraftStore.shared
    @ObservedObject private var queue = UltraSendQueue.shared
    private var title: String { IsraeliPhonePresentation.copyValue(customerCRM.name(for: conversation)) }
    private var hasUnread: Bool { conversation.unread > 0 }
    private var draft: String { drafts.text(accountID: conversation.accountID ?? "default", chatJID: conversation.jid).trimmingCharacters(in: .whitespacesAndNewlines) }
    private var pending: UltraQueuedSend? {
        queue.items.filter { $0.account == (conversation.accountID ?? "default") && $0.chat == conversation.jid && $0.state != "sent" && $0.state != "cancelled" }.max { $0.created < $1.created }
    }
    private func pendingTitle(_ state: String) -> String {
        switch state {
        case "uncertain": return "השליחה דורשת בדיקה בצ׳אט"
        case "failed": return "הודעה לא נשלחה · פתח את תור השליחה"
        case "sending": return "שולח הודעה…"
        default: return "הודעה ממתינה לחיבור"
        }
    }
    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            avatar
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title).font(.system(size: 17, weight: hasUnread ? .semibold : .medium)).lineLimit(1)
                    Spacer(minLength: 4)
                    if conversation.lastMessageAt > 0 {
                        Text(timeText).font(.caption).monospacedDigit()
                            .foregroundStyle(hasUnread ? WhatsAppVisualDesign.accent : Color.secondary)
                    }
                }
                HStack(spacing: 5) {
                    SessionMiniBadge(name: sessions.name(for: conversation.accountID))
                    if conversation.pinned == true { Image(systemName: "pin.fill").font(.caption2).foregroundStyle(.secondary) }
                    if conversation.muted == true { Image(systemName: "speaker.slash.fill").font(.caption2).foregroundStyle(.secondary) }
                    Spacer(minLength: 0)
                }
                HStack(alignment: .top, spacing: 8) {
                    if !draft.isEmpty {
                        (Text("טיוטה: ").foregroundColor(.orange) + Text(draft).foregroundColor(.secondary))
                            .font(.subheadline).lineLimit(2)
                    } else {
                        Text(conversation.preview).font(.subheadline)
                            .foregroundStyle(hasUnread ? Color.primary.opacity(0.85) : Color.secondary).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    UnreadBadge(count: conversation.unread)
                }
                if let pending {
                    Label(pendingTitle(pending.state), systemImage: ["failed", "uncertain"].contains(pending.state) ? "exclamationmark.circle" : "clock")
                        .font(.caption2).foregroundStyle(["failed", "uncertain"].contains(pending.state) ? Color.orange : Color.secondary)
                        .lineLimit(1)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12).contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        CustomerAvatarView(jid: conversation.jid, accountID: conversation.accountID, size: 58)
        .frame(
            width: 58,
            height: 58
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
            return "אתמול"
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
