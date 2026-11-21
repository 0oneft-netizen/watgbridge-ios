import SwiftUI

@MainActor
struct NewWhatsAppChatView: View {
    let conversations: [Conversation]
    let initialAccount: String?
    let onOpen: (Conversation) -> Void
    @ObservedObject private var sessions = SessionDirectory.shared
    @Environment(\.dismiss) private var dismiss
    @State private var phone = ""
    @State private var selectedAccount = ""
    @State private var scope = UserWorkspace.id
    private var available: [SessionIdentity] {
        sessions.sessions.values.filter(\.isConnected).sorted { $0.routeLabel.localizedStandardCompare($1.routeLabel) == .orderedAscending }
    }
    private var account: SessionIdentity? { available.first { $0.id == selectedAccount } }
    private var normalized: String? { NewChatPhone.digits(phone) }
    var body: some View {
        NavigationStack {
            Form {
                Section("המספר של הלקוח") {
                    TextField("0501234567 או ‎+14155552671", text: $phone)
                        .keyboardType(.phonePad).textContentType(.telephoneNumber)
                        .environment(\.layoutDirection, .leftToRight)
                    if let normalized {
                        Text(IsraeliPhonePresentation.copyValue("+" + normalized)).foregroundStyle(.secondary)
                    } else if !phone.isEmpty {
                        Text("הזן מספר ישראלי מלא, או מספר בינלאומי שמתחיל ב־+ וקוד המדינה.").font(.caption).foregroundStyle(.orange)
                    }
                }
                Section("שליחה מהחשבון") {
                    Picker("המספר השולח", selection: $selectedAccount) {
                        Text("בחר חשבון").tag("")
                        ForEach(available) { item in Text(item.routeLabel).tag(item.id) }
                    }
                    if available.isEmpty {
                        Label("אין כרגע חשבון WhatsApp מחובר", systemImage: "wifi.exclamationmark")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Button("רענון חשבונות") { Task { await sessions.refresh(); chooseDefault() } }
                        .disabled(sessions.isLoading)
                }
                Section {
                    if let account { Label("ההודעות יישלחו דרך " + account.routeLabel, systemImage: "simcard") }
                    Button("פתיחת צ׳אט") { open() }
                        .font(.headline).disabled(normalized == nil || account == nil || scope != UserWorkspace.id)
                } footer: {
                    Text("פתיחת הצ׳אט לא שולחת הודעה. לאחר הפתיחה אפשר לכתוב, להקליט ולשלוח קבצים כרגיל.")
                }
            }
            .navigationTitle("צ׳אט חדש")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("ביטול") { dismiss() } } }
            .task { chooseDefault(); await sessions.refresh(); chooseDefault() }
        }
    }
    private func chooseDefault() {
        guard scope == UserWorkspace.id else { return }
        if account != nil { return }
        selectedAccount = available.first(where: { $0.id == initialAccount })?.id ?? available.first?.id ?? ""
    }
    private func open() {
        guard scope == UserWorkspace.id, let number = normalized, let account else { return }
        let existing = conversations.first {
            ($0.accountID ?? "default") == account.id &&
            (NewChatPhone.digits(ChatIdentity.customerPhone(conversation: $0)) == number || $0.jid == number + "@s.whatsapp.net")
        }
        let conversation = existing ?? Conversation(accountID: account.id, jid: number + "@s.whatsapp.net", name: IsraeliPhonePresentation.copyValue("+" + number), displayPhone: "+" + number, lastMessage: "", lastMessageAt: 0, unread: 0, pinned: false, archived: false, muted: false)
        dismiss(); onOpen(conversation)
    }
}
