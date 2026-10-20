import SwiftUI

struct HiddenSentMessagesView: View {
    let conversation: Conversation
    @State private var workspace = UserWorkspace.id
    @State private var messages: [HiddenSentMessage] = []
    @State private var selected: HiddenSentMessage?
    @State private var confirm = false
    @State private var busy = false
    @State private var error: String?
    @State private var notice: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("עד 100 ההודעות האחרונות ששלחת בצ׳אט הזה ומחקת רק אצלך. אפשר לבקש מחיקה אצל כולם בתוך 48 שעות מהשליחה. הלקוח עשוי כבר לראות או לשמור את ההודעה.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text(SessionDirectory.shared.name(for: conversation.accountID))
                        .font(.caption)
                }
                if let notice { Text(notice).foregroundStyle(.secondary) }
                if let error { Text(error).foregroundStyle(.red) }
                if messages.isEmpty && !busy { Text("לא נמצאו הודעות ששלחת והסתרת בצ׳אט הזה") }
                ForEach(messages) { message in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(message.text.isEmpty ? "הודעת מדיה · \(message.kind)" : message.text)
                        Text(Date(timeIntervalSince1970: Double(message.createdAt)), style: .date)
                            .font(.caption).foregroundStyle(.secondary)
                        Text(Date(timeIntervalSince1970: Double(message.createdAt)), style: .time)
                            .font(.caption).foregroundStyle(.secondary)
                        Button("בקשת מחיקה אצל כולם", role: .destructive) {
                            selected = message; confirm = true
                        }.disabled(busy || Date().timeIntervalSince1970 - Double(message.createdAt) > 172800)
                    }.padding(.vertical, 6)
                }
            }
            .navigationTitle("הודעות ששלחת ומחקת אצלך")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("סגירה") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("רענון") { Task { await load() } }.disabled(busy) }
            }
            .overlay { if busy { ProgressView() } }
            .task { await load() }
            .confirmationDialog("לבקש למחוק את ההודעה גם אצל הלקוח?", isPresented: $confirm, titleVisibility: .visible) {
                if let selected {
                    Button("מחיקה אצל כולם", role: .destructive) { Task { await revoke(selected) } }
                }
                Button("ביטול", role: .cancel) {}
            } message: { Text("המחיקה כפופה לקבלת הבקשה בווצאפ. היא לא מבטלת קריאה או עותק שנשמר קודם.") }
        }
    }
    @MainActor private func load() async {
        guard !busy, workspace == UserWorkspace.id else { return }
        busy = true; error = nil
        defer { busy = false }
        do { messages = try await MessageDeleteAPI.hidden(account: conversation.accountID ?? "default", chat: conversation.jid, workspace: workspace) }
        catch { if workspace == UserWorkspace.id { self.error = error.localizedDescription } }
    }
    @MainActor private func revoke(_ message: HiddenSentMessage) async {
        guard !busy, workspace == UserWorkspace.id else { return }
        busy = true; error = nil; notice = nil
        defer { busy = false }
        do {
            try await MessageDeleteAPI.remove(account: conversation.accountID ?? "default", chat: conversation.jid,
                message: message.messageID, everyone: true, workspace: workspace)
            messages.removeAll { $0.id == message.id }
            notice = "בקשת המחיקה נשלחה לווצאפ."
        } catch { if workspace == UserWorkspace.id { self.error = error.localizedDescription } }
    }
}
