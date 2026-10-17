import SwiftUI
import LinkPresentation

struct UltraRecentChats: View {
    let current: Conversation
    let onSelect: (Conversation) -> Void
    @ObservedObject private var store = UltraChatStore.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(store.recents.filter { $0.id != current.id }) { item in
                Button { dismiss(); onSelect(item.conversation) } label: {
                    VStack(alignment: .leading) {
                        Text(CustomerCRMDirectory.shared.name(for: item.conversation)).foregroundStyle(.primary)
                        Text(SessionDirectory.shared.name(for: item.conversation.accountID)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }.navigationTitle("צ׳אטים אחרונים").toolbar { ToolbarItem(placement: .topBarLeading) { Button("סגירה") { dismiss() } } }
        }.presentationDetents([.medium, .large])
    }
}
struct UltraPinnedMessages: View {
    let conversation: Conversation
    let onSelect: (Message) -> Void
    @ObservedObject private var store = UltraChatStore.shared
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(store.pins.filter { $0.chatJID == conversation.jid && ($0.accountID ?? "default") == (conversation.accountID ?? "default") }) { message in
                Button { onSelect(message); dismiss() } label: {
                    VStack(alignment: .leading) { Text(message.text.isEmpty ? message.type : message.text).lineLimit(4); Text(Date(timeIntervalSince1970: Double(message.createdAt)).formatted()).font(.caption).foregroundStyle(.secondary) }
                }.swipeActions { Button("בטל נעיצה", role: .destructive) { store.togglePin(message) } }
            }.navigationTitle("נעיצות אישיות").toolbar { ToolbarItem(placement: .topBarLeading) { Button("סגירה") { dismiss() } } }
        }
    }
}
struct UltraMessageSelection: View {
    let messages: [Message]
    @State private var selected = Set<String>()
    @State private var target = "he"
    @State private var busy = false
    @State private var error: String?
    @State private var forward = false
    @ObservedObject private var store = UltraChatStore.shared
    @Environment(\.dismiss) private var dismiss
    private var chosen: [Message] { messages.filter { selected.contains(UltraChatStore.key($0)) } }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("שפת תרגום", selection: $target) { ForEach(UltraSuiteAPI.languages, id: \.0) { Text($0.1).tag($0.0) } }
                    Text("התרגום משתמש במפתח OpenAI של המשתמש. הטקסטים שנבחרו יישלחו לספק, בתשלום לפי שימוש. המקור אינו משתנה.").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("תרגם נבחרות") { Task { busy = true; defer { busy = false }; do { try await store.translate(chosen, target: target) } catch { self.error = error.localizedDescription } } }
                        Button("העבר נבחרות") { forward = true }
                    }.disabled(chosen.isEmpty || busy)
                    Text("\(chosen.count) נבחרו · עד 20 בכל פעולה").font(.caption)
                    if busy { ProgressView() }
                    if let error { Text(error).foregroundStyle(.red) }
                }
                ForEach(messages.filter { !MessageMediaPolicy.isViewOnce($0) && $0.deletedRemote != true && $0.deletedLocal != true }) { message in
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle(isOn: Binding(get: { selected.contains(UltraChatStore.key(message)) }, set: { value in
                            if value && selected.count < 20 { selected.insert(UltraChatStore.key(message)) } else { selected.remove(UltraChatStore.key(message)) }
                        })) { Text(message.text.isEmpty ? message.type : message.text).lineLimit(5) }
                        if let translated = store.translation(message, target: target) { Text(translated).foregroundStyle(ChatDesign.accent).textSelection(.enabled) }
                    }
                }
            }.navigationTitle("בחירת הודעות")
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("סגירה") { dismiss() } } }
            .sheet(isPresented: $forward) { ForwardMessageView(messages: chosen) }
        }
    }
}
struct UltraOutgoingTranslation: View {
    let text: String
    var conversation: Conversation? = nil
    let onUse: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var target = "en"
    @State private var workspace = UserWorkspace.id
    @State private var translated = ""
    @State private var busy = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("המקור") { Text(text).textSelection(.enabled) }
                Picker("שפת הלקוח", selection: Binding(get: { target }, set: { code in
                    target = code
                    guard UserWorkspace.id == workspace, let conversation else { return }
                    Task { do { var p = try await UltraPreferenceStore.shared.load(conversation); p.language = code; p.manual = true; try await UltraPreferenceStore.shared.save(p, chat: conversation) } catch { self.error = "לא ניתן לשמור את שפת הלקוח." } }
                })) { ForEach(UltraSuiteAPI.languages, id: \.0) { Text($0.1).tag($0.0) } }
                Text("הטקסט יישלח ל־OpenAI באמצעות המפתח של המשתמש שלך. ייתכן חיוב שימוש.").font(.caption)
                Button("תרגם לתצוגה מקדימה") { Task {
                    guard UserWorkspace.id == workspace else { return }
                    busy = true; translated = ""; defer { busy = false }
                    do { translated = try await UltraSuiteAPI.translate([.init(key: "draft", text: text)], target: target).first?.text ?? "" } catch { self.error = error.localizedDescription }
                } }.disabled(busy || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if busy { ProgressView() }
                if !translated.isEmpty {
                    Section("אפשר לערוך לפני השליחה") { TextEditor(text: $translated).frame(minHeight: 120) }
                    Button("השתמש בטיוטה — ללא שליחה") { onUse(translated); dismiss() }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }.task { if let conversation { _ = try? await UltraPreferenceStore.shared.load(conversation); let language = UltraPreferenceStore.shared.language(conversation); if !language.isEmpty { target = language } } }
            .onChange(of: target) { _, _ in translated = "" }
            .navigationTitle("תרגום לפני שליחה").toolbar { ToolbarItem(placement: .topBarLeading) { Button("ביטול") { dismiss() } } }
        }
    }
}
struct UltraOutboxView: View {
    @ObservedObject private var queue = UltraSendQueue.shared
    var body: some View {
        List {
            Section {
                Text("הודעות וקבצים נשמרים בתור המקומי. בקשת ניסיון חוזר משתמשת באותו מזהה. כשהשליחה אינה ודאית, לא נשלח עותק חדש אוטומטית.").font(.caption)
                Button("נסה שליחות שממתינות לחיבור") { queue.kick() }
            }
            ForEach(queue.items.reversed()) { item in
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.summary).lineLimit(4)
                    Text(SessionDirectory.shared.name(for: item.account)).font(.caption)
                    Text(label(item.state)).font(.caption.weight(.semibold)).foregroundStyle(item.state == "sent" ? .green : .orange)
                    if !item.error.isEmpty { Text(item.error).font(.caption).foregroundStyle(.secondary) }
                    HStack {
                        if item.state == "queued" || item.state == "failed" { Button("נסה שוב באותו מזהה") { queue.retry(item.id) } }
                        if item.state == "uncertain" { Button("בדוק קבלה בשרת") { Task { await queue.reconcile(item.id) } } }
                        if item.state != "sending" { Button("הסר מהרשימה", role: .destructive) { queue.remove(item.id) } }
                    }.font(.caption)
                }.padding(.vertical, 4)
            }
        }.navigationTitle("תור שליחה")
    }
    private func label(_ state: String) -> String {
        switch state { case "sent": return "התקבל בשירות השליחה"; case "sending": return "מתבצעת שליחה"; case "uncertain": return "נדרשת בדיקה — ללא שליחה כפולה"; case "failed": return "נדרשת פעולה"; default: return "ממתין לחיבור / ניסיון חוזר" }
    }
}
struct UltraLinkPreview: View {
    let text: String
    @State private var metadata: LPLinkMetadata?
    @State private var hidden = false
    @State private var loading = false
    @State private var error = false
    private var url: URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
              let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)), let url = match.url,
              ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
    var body: some View {
        Group {
            if let url, !hidden {
                HStack {
                    if let metadata { UltraLinkCard(metadata: metadata).frame(height: 95) }
                    else { VStack(alignment: .leading) { Text(url.host ?? "קישור").font(.caption); Button(loading ? "טוען…" : error ? "נסה תצוגה מקדימה שוב" : "טען תצוגה מקדימה לקישור") { Task { await load(url) } }.font(.caption).disabled(loading) } }
                    Spacer(minLength: 4)
                    Button { hidden = true; metadata = nil } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("הסר תצוגה מקדימה")
                }.padding(8).background(.thinMaterial)
            }
        }.onChange(of: url) { _, _ in hidden = false; metadata = nil; error = false }
    }
    private func load(_ chosen: URL) async {
        loading = true; defer { loading = false }; error = false
        let provider = LPMetadataProvider(); provider.timeout = 10
        do { let result = try await provider.startFetchingMetadata(for: chosen); if url == chosen && !hidden { metadata = result } } catch { self.error = true }
    }
}
private struct UltraLinkCard: UIViewRepresentable {
    let metadata: LPLinkMetadata
    func makeUIView(context: Context) -> LPLinkView { LPLinkView(metadata: metadata) }
    func updateUIView(_ uiView: LPLinkView, context: Context) { uiView.metadata = metadata }
}

struct UltraChatPanel: View {
    let conversation: Conversation
    let messages: [Message]
    @Binding var autoTranslate: Bool
    let draftText: String
    let onDraft: (String) -> Void
    let onChat: (Conversation) -> Void
    let onMessage: (Message) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var workspace = UserWorkspace.id
    @State private var preferenceError: String?
    var body: some View {
        NavigationStack {
            List {
                Section("מעבר ומדיה") {
                    NavigationLink { UltraRecentChats(current: conversation) { chat in dismiss(); onChat(chat) } } label: { Label("צ׳אטים אחרונים", systemImage: "rectangle.stack") }
                    NavigationLink { UltraMediaLibrary(conversation: conversation, onShow: { message in dismiss(); onMessage(message) }) } label: { Label("תמונות וסרטונים בשיחה", systemImage: "photo.on.rectangle") }
                    NavigationLink { UltraPinnedMessages(conversation: conversation) { message in dismiss(); onMessage(message) } } label: { Label("נעיצות אישיות", systemImage: "pin") }
                    NavigationLink { UltraMessageSelection(messages: messages) } label: { Label("בחירה מרובה: העברה ותרגום", systemImage: "checkmark.circle") }
                }
                Section("תרגום") {
                    NavigationLink { UltraChatPreferenceView(conversation: conversation, onAutoChange: { autoTranslate = $0 }) } label: { Label("שפת לקוח קבועה והשתקה מתוזמנת", systemImage: "globe") }
                    Toggle("תרגם הודעות נכנסות לעברית", isOn: Binding(get: { autoTranslate }, set: { enabled in
                        autoTranslate = enabled
                        let scope = workspace
                        Task { guard UserWorkspace.id == scope else { return }; do { var p = try await UltraPreferenceStore.shared.load(conversation); guard UserWorkspace.id == scope else { return }; p.autoTranslate = enabled; try await UltraPreferenceStore.shared.save(p, chat: conversation); preferenceError = nil } catch { preferenceError = "העדפת התרגום לא נשמרה בשרת. בדוק את החיבור ונסה שוב." } }
                    }))
                    if let preferenceError { Text(preferenceError).font(.caption).foregroundStyle(.orange) }
                    Text("בהפעלה, עד 12 הודעות טקסט נכנסות אחרונות וחדשות יישלחו ל־OpenAI באמצעות המפתח של המשתמש. התרגום מופיע לצד המקור וייתכן חיוב לפי שימוש. ההגדרה היא לשיחה הזאת בלבד.").font(.caption).foregroundStyle(.secondary)
                    NavigationLink { UltraOutgoingTranslation(text: draftText, conversation: conversation) { text in onDraft(text); dismiss() } } label: { Label("תרגם את הטיוטה לפני שליחה", systemImage: "character.bubble") }.disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                NavigationLink { UltraOutboxView() } label: { Label("תור שליחה ובדיקת ניסיונות", systemImage: "tray.and.arrow.up") }
            }.navigationTitle("כלים לצ׳אט").toolbar { ToolbarItem(placement: .topBarLeading) { Button("סגירה") { dismiss() } } }
        }
    }
}
