import SwiftUI

struct ForwardMessageView: View {
    let messages: [Message]
    init(message: Message) { messages = [message] }
    init(messages: [Message]) { self.messages = Array(messages.prefix(20)) }
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var selected = Set<String>()
    @State private var completed = Set<String>()
    @State private var search = ""
    @State private var sending = false
    @State private var error: String?
    @State private var confirm = false
    @State private var submitted = 0
    private var visible: [Conversation] { conversations.filter { search.isEmpty || CustomerCRMDirectory.shared.name(for: $0).localizedCaseInsensitiveContains(search) || $0.cleanNumber.contains(search) } }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("\(messages.count) הודעות · \(selected.count) שיחות נבחרו").font(.subheadline)
                    Text("כל נמען יקבל מהמספר שמופיע לידו. ההעברה יוצרת עותק של התוכן; אין שימור של סימון העברה מקורי.").font(.caption).foregroundStyle(.secondary)
                    Button("אשר העברה לנמענים שנבחרו") { confirm = true }.disabled(selected.isEmpty || sending)
                    if sending { ProgressView("נוספו לתור \(submitted) פריטים") }
                    if let error { Text(error).foregroundStyle(.red) }
                }
                ForEach(visible) { chat in
                    Toggle(isOn: Binding(get: { selected.contains(chat.id) }, set: { value in if value && selected.count < 20 { selected.insert(chat.id) } else { selected.remove(chat.id) } })) {
                        VStack(alignment: .leading) { Text(CustomerCRMDirectory.shared.name(for: chat)); Text("שולח: " + SessionDirectory.shared.name(for: chat.accountID)).font(.caption).foregroundStyle(.secondary) }
                    }.disabled(sending)
                }
            }.navigationTitle("העברה למספר צ׳אטים").searchable(text: $search)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("סגירה") { dismiss() }.disabled(sending) } }
            .interactiveDismissDisabled(sending)
            .confirmationDialog("להעביר \(messages.count) הודעות ל־\(selected.count) שיחות?", isPresented: $confirm, titleVisibility: .visible) { Button("העבר") { Task { await send() } } }
            .task { do { conversations = try await APIClient.shared.fetchConversations() } catch { self.error = error.localizedDescription } }
        }
    }
    private func send() async {
        guard !sending else { return }; sending = true; error = nil; defer { sending = false }
        let scope = UserWorkspace.id
        do {
            for chat in conversations where selected.contains(chat.id) {
                for message in messages {
                    try Task.checkCancellation(); guard scope == UserWorkspace.id else { throw CancellationError() }
                    let key = chat.id + "|" + UltraChatStore.key(message)
                    if completed.contains(key) { continue }
                    guard MessageMediaPolicy.mayShare(message), message.deletedRemote != true else { continue }
                    if message.type == "text" { try await APIClient.shared.sendMessage(chatJID: chat.jid, text: message.text, accountID: chat.accountID ?? "default") }
                    else { try await APIClient.shared.forwardMedia(message, to: chat) }
                    completed.insert(key); submitted += 1
                }
            }
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
