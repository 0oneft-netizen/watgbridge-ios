import SwiftUI

@MainActor struct ChatMuteControls: View {
    let conversation: Conversation
    @State private var muted = false
    @State private var busy = false
    @State private var loaded = false
    @State private var error: String?
    @State private var scope = UserWorkspace.id
    var body: some View {
        Section("התראות מהלקוח") {
            Toggle("השתק הודעות והתראות", isOn: Binding(get: { muted }, set: { value in Task { await update(value) } }))
                .disabled(busy || !loaded)
            Text("ההשתקה חלה גם על WA Alerts ועל התראות האפליקציה, עבור המספר והשיחה האלה.")
                .font(.caption).foregroundStyle(.secondary)
            if let error { Text(error).foregroundStyle(.red) }
        }
        .task {
            do {
                let p = try await UltraPreferenceStore.shared.load(conversation)
                guard scope == UserWorkspace.id else { return }
                muted = conversation.muted == true || p.muteUntil == -1 || p.muteUntil > Int64(Date().timeIntervalSince1970)
                loaded = true
            } catch { self.error = "לא ניתן לטעון את ההשתקה. פתח מחדש את הכרטיס כדי לנסות שוב." }
        }
    }
    private func update(_ value: Bool) async {
        guard !busy, scope == UserWorkspace.id else { return }
        busy = true; defer { busy = false }
        do {
            try await APIClient.shared.conversationAction(chatJID: conversation.jid, action: "mute", value: value, accountID: conversation.accountID ?? "default")
            guard scope == UserWorkspace.id else { return }
            muted = value; error = nil
            _ = try? await UltraPreferenceStore.shared.load(conversation)
            NotificationCenter.default.post(name: Notification.Name("bridgeRealtimeUpdate"), object: nil)
        } catch { self.error = "ההשתקה לא נשמרה. אפשר לנסות שוב." }
    }
}
